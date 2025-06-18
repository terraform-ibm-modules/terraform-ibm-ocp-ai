# Cloud Automation for Red Hat OpenShift AI (Fully configurable)

## Description

This solution simplifies the deployment of Red Hat OpenShift clusters on IBM Cloud, pre-integrating them with essential AI components. It accelerates the setup of machine learning environments, reducing the complexity of AI infrastructure management and allowing data scientists and developers to focus on model development and deployment.

:exclamation: **Important:** This solution is not intended to be called by other modules because it contains a provider configuration and is not compatible with the `for_each`, `count`, and `depends_on` arguments. For more information, see [Providers Within Modules](https://developer.hashicorp.com/terraform/language/modules/develop/providers).

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

No requirements.

### Modules

No modules.

### Resources

No resources.

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_worker_pools"></a> [additional\_worker\_pools](#input\_additional\_worker\_pools) | List of additional worker pools configured exclusively for the GPU machine type to support AI workload requirements within the cluster. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-ocp-ai/blob/main/solutions/fully-configurable/DA_docs.md#options-with-worker-pools) | <pre>list(object({<br/>    vpc_subnets = optional(list(object({<br/>      id         = string<br/>      zone       = string<br/>      cidr_block = string<br/>    })), [])<br/>    pool_name                     = string<br/>    machine_type                  = string<br/>    workers_per_zone              = number<br/>    operating_system              = string<br/>    labels                        = optional(map(string))<br/>    minSize                       = optional(number)<br/>    secondary_storage             = optional(string)<br/>    maxSize                       = optional(number)<br/>    enableAutoscaling             = optional(bool)<br/>    additional_security_group_ids = optional(list(string))<br/>  }))</pre> | <pre>[<br/>  {<br/>    "machine_type": "gx3.16x80.l4",<br/>    "operating_system": "RHCOS",<br/>    "pool_name": "gpu",<br/>    "secondary_storage": "300gb.5iops-tier",<br/>    "workers_per_zone": 1<br/>  }<br/>]</pre> | no |
| <a name="input_default_worker_pool_machine_type"></a> [default\_worker\_pool\_machine\_type](#input\_default\_worker\_pool\_machine\_type) | Specifies the machine type for the default worker pool. This determines the CPU, memory, and disk resources available to each worker node. For OpenShift AI installation, machines should have atleast 8 vcpu, 32GB RAM and GPU. Refer [IBM Cloud documentation for available machine types](https://cloud.ibm.com/docs/openshift?topic=openshift-vpc-flavors) | `string` | `"bx2.8x32"` | no |
| <a name="input_default_worker_pool_operating_system"></a> [default\_worker\_pool\_operating\_system](#input\_default\_worker\_pool\_operating\_system) | Provide the operating system for the worker nodes in the default worker pool. [Learn more](https://cloud.ibm.com/docs/openshift?topic=openshift-ai-addon-install&interface=ui#ai-min) | `string` | `"RHCOS"` | no |
| <a name="input_default_worker_pool_workers_per_zone"></a> [default\_worker\_pool\_workers\_per\_zone](#input\_default\_worker\_pool\_workers\_per\_zone) | Defines the number of worker nodes to provision in each zone for the default worker pool. Overall cluster must have at least 2 worker nodes, but individual worker pools may have fewer nodes per zone. [Learn More](https://cloud.ibm.com/docs/openshift?topic=openshift-ai-addon-install&interface=ui#ai-min) | `number` | `2` | no |
| <a name="input_existing_resource_group_name"></a> [existing\_resource\_group\_name](#input\_existing\_resource\_group\_name) | The name of an existing resource group to provision the cluster. | `string` | `"Default"` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | The prefix to be added to all resources created by this solution. To skip using a prefix, set this value to null or an empty string. The prefix must begin with a lowercase letter and may contain only lowercase letters, digits, and hyphens '-'. It should not exceed 16 characters, must not end with a hyphen('-'), and can not contain consecutive hyphens ('--'). Example: `prod-0205-ocpai`. [Learn more](https://terraform-ibm-modules.github.io/documentation/#/prefix.md) | `string` | n/a | yes |

### Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
