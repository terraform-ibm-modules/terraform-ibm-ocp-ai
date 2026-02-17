// Tests in this file are run in the PR pipeline and the continuous testing pipeline
package test

import (
	"bytes"
	"crypto/rand"
	"fmt"
	"log"
	"math/big"
	"os"
	"os/exec"
	"testing"

	"github.com/IBM/go-sdk-core/v5/core"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/cloudinfo"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/common"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testaddons"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testschematic"
)

// Use existing resource group
const resourceGroup = "geretain-test-resources"

const fullyConfigurableTerraformDir = "solutions/fully-configurable"
const quickStartTerraformDir = "solutions/quickstart"
const terraformVersion = "terraform_v1.12.2" // This should match the version in the ibm_catalog.json

// Define a struct with fields that match the structure of the YAML data
const yamlLocation = "../common-dev-assets/common-go-assets/common-permanent-resources.yaml"

var validClusterRegions = []string{
	"br-sao",
	"eu-gb",
	"jp-tok",
}

var permanentResources map[string]interface{}

// TestMain will be run before any parallel tests, used to read data from yaml for use with tests
func TestMain(m *testing.M) {
	var err error
	permanentResources, err = common.LoadMapFromYaml(yamlLocation)
	if err != nil {
		log.Fatal(err)
	}
	os.Exit(m.Run())
}

func validateEnvVariable(t *testing.T, varName string) string {
	val, present := os.LookupEnv(varName)
	require.True(t, present, "%s environment variable not set", varName)
	require.NotEqual(t, "", val, "%s environment variable is empty", varName)
	return val
}

func createContainersApikey(t *testing.T, region string, rg string) {

	err := os.Setenv("IBMCLOUD_API_KEY", validateEnvVariable(t, "TF_VAR_ibmcloud_api_key"))
	require.NoError(t, err, "Failed to set IBMCLOUD_API_KEY environment variable")
	scriptPath := "../common-dev-assets/scripts/iks-api-key-reset/reset_iks_api_key.sh"
	cmd := exec.Command("bash", scriptPath, region, rg)
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	// Execute the command
	if err := cmd.Run(); err != nil {
		log.Fatalf("Failed to execute script: %v\nStderr: %s", err, stderr.String())
	}
	// Print script output
	fmt.Println(stdout.String())
}

func setupOptions(t *testing.T, prefix string, dir string) *testhelper.TestOptions {
	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:                    t,
		TerraformDir:               dir,
		Prefix:                     prefix,
		ResourceGroup:              resourceGroup,
		CheckApplyResultForUpgrade: true,
	})
	return options
}

func setupQuickstartOptions(t *testing.T, prefix string) *testschematic.TestSchematicOptions {
	rand, err := rand.Int(rand.Reader, big.NewInt(int64(len(validClusterRegions))))
	if err != nil {
		fmt.Println("Error generating random number:", err)
		return nil
	}
	region := validClusterRegions[rand.Int64()]
	options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
		Testing: t,
		Prefix:  prefix,
		TarIncludePatterns: []string{
			"*.tf",
			quickStartTerraformDir + "/*.tf",
		},

		TemplateFolder:             quickStartTerraformDir,
		Tags:                       []string{"test-schematic"},
		DeleteWorkspaceOnFail:      false,
		WaitJobCompleteMinutes:     360,
		Region:                     region,
		TerraformVersion:           terraformVersion,
		CheckApplyResultForUpgrade: true,
		ResourceGroup:              resourceGroup,
	})
	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
		{Name: "prefix", Value: options.Prefix, DataType: "string"},
		{Name: "existing_resource_group_name", Value: options.ResourceGroup, DataType: "string"},
		{Name: "region", Value: region, DataType: "string"},
	}
	return options
}

// Consistency test
func TestRunFullyConfigurable(t *testing.T) {
	t.Parallel()
	options := setupOptions(t, "ocp-ai", fullyConfigurableTerraformDir)

	options.TerraformVars = map[string]interface{}{
		"prefix":                       options.Prefix,
		"existing_resource_group_name": resourceGroup,
	}

	// Temp workaround for https://cloud.ibm.com/docs/ibm-cloud-provider-for-terraform?topic=ibm-cloud-provider-for-terraform-known-issues#ki-apikey-error
	createContainersApikey(t, options.Region, resourceGroup)

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

// Upgrade test
func TestRunUpgradeExample(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "ai-upg", fullyConfigurableTerraformDir)
	options.TerraformVars = map[string]interface{}{
		"prefix":                       options.Prefix,
		"existing_resource_group_name": resourceGroup,
	}

	// Temp workaround for https://cloud.ibm.com/docs/ibm-cloud-provider-for-terraform?topic=ibm-cloud-provider-for-terraform-known-issues#ki-apikey-error
	createContainersApikey(t, options.Region, resourceGroup)

	output, err := options.RunTestUpgrade()
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
		assert.NotNil(t, output, "Expected some output")
	}
}

/*******************************************************************
* TESTS FOR THE TERRAFORM BASED QUICKSTART DEPLOYABLE ARCHITECTURE *
********************************************************************/
func TestRunQuickstartSchematics(t *testing.T) {
	t.Parallel()

	options := setupQuickstartOptions(t, "ai-qs")

	// Temp workaround for https://cloud.ibm.com/docs/ibm-cloud-provider-for-terraform?topic=ibm-cloud-provider-for-terraform-known-issues#ki-apikey-error
	createContainersApikey(t, options.Region, options.ResourceGroup)

	err := options.RunSchematicTest()
	assert.Nil(t, err, "This should not have errored")
}

// Upgrade test for the Quickstart DA
func TestRunQuickstartUpgradeSchematics(t *testing.T) {
	t.Parallel()

	options := setupQuickstartOptions(t, "ai-qs-upg")
	err := options.RunSchematicUpgradeTest()
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
	}
}

/*******************************************************************
* Addons test *
********************************************************************/

func TestAddonDefaultConfiguration(t *testing.T) {
	t.Parallel()

	region := "au-syd"

	options := testaddons.TestAddonsOptionsDefault(&testaddons.TestAddonOptions{
		Testing:       t,
		Prefix:        "ai-add",
		ResourceGroup: resourceGroup,
		QuietMode:     false, // Suppress logs except on failure
	})

	options.AddonConfig = cloudinfo.NewAddonConfigTerraform(
		options.Prefix,
		"deploy-arch-ibm-ocp-ai",
		"fully-configurable",
		map[string]interface{}{
			"region":                       region,
			"existing_resource_group_name": options.ResourceGroup,
		},
	)

	options.AddonConfig.Dependencies = []cloudinfo.AddonConfig{
		//	use existing secrets manager instance to help prevent hitting trial instance limit in account
		{
			OfferingName:   "deploy-arch-ibm-secrets-manager",
			OfferingFlavor: "fully-configurable",
			Inputs: map[string]interface{}{
				"existing_secrets_manager_crn":         permanentResources["privateOnlySecMgrCRN"],
				"service_plan":                         "__NULL__", // no plan value needed when using existing SM
				"skip_secrets_manager_iam_auth_policy": true,       // since using an existing Secrets Manager instance, attempting to re-create auth policy can cause conflicts if the policy already exists
				"secret_groups":                        []string{}, // passing empty array for secret groups as default value is creating general group and it will cause conflicts as we are using an existing SM
			},
		},
		// Disable target / route creation to prevent hitting quota in account
		{
			OfferingName:   "deploy-arch-ibm-cloud-monitoring",
			OfferingFlavor: "fully-configurable",
			Inputs: map[string]interface{}{
				"enable_metrics_routing_to_cloud_monitoring": false,
			},
			Enabled: core.BoolPtr(true),
		},
		{
			OfferingName:   "deploy-arch-ibm-activity-tracker",
			OfferingFlavor: "fully-configurable",
			Inputs: map[string]interface{}{
				"enable_activity_tracker_event_routing_to_cloud_logs": false,
			},
			Enabled: core.BoolPtr(true),
		},
	}

	// Temp workaround for https://cloud.ibm.com/docs/ibm-cloud-provider-for-terraform?topic=ibm-cloud-provider-for-terraform-known-issues#ki-apikey-error
	createContainersApikey(t, region, options.ResourceGroup)

	err := options.RunAddonTest()
	require.NoError(t, err)
}
