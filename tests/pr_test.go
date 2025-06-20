// Tests in this file are run in the PR pipeline and the continuous testing pipeline
package test

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
)

// Use existing resource group
const resourceGroup = "geretain-test-resources"

const fullyConfigurableTerraformDir = "solutions/fully-configurable"
const quickStartTerraformDir = "solutions/quickstart"

func setupOptions(t *testing.T, prefix string, dir string) *testhelper.TestOptions {

	options := testhelper.TestOptionsDefault(&testhelper.TestOptions{
		Testing:      t,
		TerraformDir: dir,
		Prefix:       prefix,
	})
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
	output, err := options.RunTestUpgrade()
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
		assert.NotNil(t, output, "Expected some output")
	}
}

func TestRunQuickstartDA(t *testing.T) {
	t.Parallel()
	options := setupOptions(t, "qs-da", quickStartTerraformDir)

	options.TerraformVars = map[string]interface{}{
		"prefix":                       options.Prefix,
		"existing_resource_group_name": resourceGroup,
	}
	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}
