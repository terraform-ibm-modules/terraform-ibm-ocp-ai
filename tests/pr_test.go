package test

import (
	"fmt"
	"log"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
)

const fullyConfigurableTerraformDir = "solutions/fully-configurable"

func TestTerraformCompleteTest(t *testing.T) {
	t.Parallel()
	options := testhelper.TestOptionsDefault(&testhelper.TestOptions{
		Testing:      t,
		TerraformDir: fullyConfigurableTerraformDir,
	})

	prefix := fmt.Sprintf("ocp-ai-da-%s", strings.ToLower(random.UniqueId()))

	options.TerraformVars = map[string]interface{}{
		"prefix": prefix,
	}

	_, err := options.RunTestConsistency()
	if err != nil {
		log.Fatal(err)
	}
}
