package test

import (
	"log"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

const fullyConfigurableTerraformDir = "./../solutions/fully-configurable"

type TerraformTestConfig struct {
	TerraformDir string
	Vars         map[string]interface{}
}

func TestTerraformCompleteTest(t *testing.T) {
	t.Parallel()
	options := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: fullyConfigurableTerraformDir,
		Vars: map[string]interface{}{
			"prefix":                               "test-prefix",
			"existing_resource_group_name":         "Default",
			"default_worker_pool_machine_type":     "gx3.16x80.l4",
			"default_worker_pool_workers_per_zone": 2,
			"default_worker_pool_operating_system": "RHEL_9_64",
			"default_gpu_worker_pool_storage":      "300gb.5iops-tier",
		},
		Upgrade: true,
	})
	_, err := terraform.InitAndApplyE(t, options)
	if err != nil {
		log.Fatal("Terraform apply failed")
	}

	terraform.Destroy(t, options)

}
