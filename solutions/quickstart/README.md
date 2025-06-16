# Cloud Automation for Red Hat OpenShift AI

This quickstart architecture creates an instance of OpenShift AI and supports provisioning of the following resources:

- A `resource group`, if one is not passed in.
- A `Red Hat OpenShift` on IBM Cloud cluster with GPU support, deployed within a secure and isolated `Virtual Private Cloud (VPC)`.
- The `OpenShift AI` add-on enabled on the cluster.

![Openshift-AI-deployable-architecture](../../reference-architecture/deployable-architecture-ocp-ai-cluster-qs.svg)

:exclamation: **Important:** This solution is not intended to be called by other modules because it contains a provider configuration and is not compatible with the `for_each`, `count`, and `depends_on` arguments. For more information, see [Providers Within Modules](https://developer.hashicorp.com/terraform/language/modules/develop/providers).

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.9.0 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | 1.79.1 |

### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ocp_base"></a> [ocp\_base](#module\_ocp\_base) | terraform-ibm-modules/base-ocp-vpc/ibm | 3.49.0 |
| <a name="module_resource_group"></a> [resource\_group](#module\_resource\_group) | terraform-ibm-modules/resource-group/ibm | 1.2.0 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-ibm-modules/landing-zone-vpc/ibm | 7.23.12 |

### Resources

No resources.

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_tags"></a> [access\_tags](#input\_access\_tags) | A list of access tags to apply to the resources created by the module. | `list(string)` | `[]` | no |
| <a name="input_additional_worker_pools"></a> [additional\_worker\_pools](#input\_additional\_worker\_pools) | List of additional worker pools configured exclusively for the GPU machine type to support AI workload requirements within the cluster. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-ocp-ai/blob/main/solutions/fully-configurable/DA_docs.md#options-with-worker-pools) | <pre>list(object({<br/>    vpc_subnets = optional(list(object({<br/>      id         = string<br/>      zone       = string<br/>      cidr_block = string<br/>    })), [])<br/>    pool_name                     = string<br/>    machine_type                  = string<br/>    workers_per_zone              = number<br/>    operating_system              = string<br/>    labels                        = optional(map(string))<br/>    minSize                       = optional(number)<br/>    secondary_storage             = optional(string)<br/>    maxSize                       = optional(number)<br/>    enableAutoscaling             = optional(bool)<br/>    additional_security_group_ids = optional(list(string))<br/>  }))</pre> | <pre>[<br/>  {<br/>    "machine_type": "gx3.16x80.l4",<br/>    "operating_system": "RHCOS",<br/>    "pool_name": "gpu-2",<br/>    "workers_per_zone": 2<br/>  }<br/>]</pre> | no |
| <a name="input_addons"></a> [addons](#input\_addons) | Map of OCP cluster add-on versions to install (NOTE: The 'vpc-block-csi-driver' add-on is installed by default for VPC clusters and 'ibm-storage-operator' is installed by default in OCP 4.15 and later, however you can explicitly specify it here if you wish to choose a later version than the default one). For full list of all supported add-ons and versions, see https://cloud.ibm.com/docs/containers?topic=containers-supported-cluster-addon-versions. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-ocp-virtualization/blob/main/solutions/quickstart/DA_docs.md#options-with-addons) | <pre>object({<br/>    openshift-ai = optional(object({<br/>      version         = optional(string)<br/>      parameters_json = optional(string)<br/>    }))<br/>  })</pre> | <pre>{<br/>  "openshift-ai": {<br/>    "version": "416"<br/>  }<br/>}</pre> | no |
| <a name="input_address_prefix"></a> [address\_prefix](#input\_address\_prefix) | The IP range that will be defined for the VPC for a certain location. Use only with manual address prefixes. | `string` | `"10.245.0.0/24"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of new IBM Cloud OpenShift Cluster | `string` | `"ocp-ai"` | no |
| <a name="input_default_worker_pool_machine_type"></a> [default\_worker\_pool\_machine\_type](#input\_default\_worker\_pool\_machine\_type) | Specifies the machine type for the default worker pool. This determines the CPU, memory, and disk resources available to each worker node. For OpenShift AI installation, machines should have atleast 8 vcpu, 32GB RAM and GPU. Refer [IBM Cloud documentation for available machine types](https://cloud.ibm.com/docs/openshift?topic=openshift-vpc-flavors) | `string` | `"bx2.8x32"` | no |
| <a name="input_default_worker_pool_operating_system"></a> [default\_worker\_pool\_operating\_system](#input\_default\_worker\_pool\_operating\_system) | Provide the operating system for the worker nodes in the default worker pool. [Learn more](https://cloud.ibm.com/docs/openshift?topic=openshift-ai-addon-install&interface=ui#ai-min) | `string` | `"RHCOS"` | no |
| <a name="input_default_worker_pool_workers_per_zone"></a> [default\_worker\_pool\_workers\_per\_zone](#input\_default\_worker\_pool\_workers\_per\_zone) | Defines the number of worker nodes to provision in each zone for the default worker pool. Overall cluster must have at least 2 worker nodes, but individual worker pools may have fewer nodes per zone. [Learn More](https://cloud.ibm.com/docs/openshift?topic=openshift-ai-addon-install&interface=ui#ai-min) | `number` | `2` | no |
| <a name="input_existing_resource_group_name"></a> [existing\_resource\_group\_name](#input\_existing\_resource\_group\_name) | Name of the existing resource group.  Required if not creating new resource group | `string` | `"Default"` | no |
| <a name="input_ibmcloud_api_key"></a> [ibmcloud\_api\_key](#input\_ibmcloud\_api\_key) | The IBM Cloud API key. | `string` | n/a | yes |
| <a name="input_manage_all_addons"></a> [manage\_all\_addons](#input\_manage\_all\_addons) | Instructs Terraform to manage all cluster addons, even if addons were installed outside of the module. If set to 'true' this module destroys any addons that were installed by other sources. | `bool` | `false` | no |
| <a name="input_ocp_entitlement"></a> [ocp\_entitlement](#input\_ocp\_entitlement) | Value that is applied to the entitlements for OCP cluster provisioning | `string` | `null` | no |
| <a name="input_ocp_version"></a> [ocp\_version](#input\_ocp\_version) | The version of the OpenShift cluster. | `string` | `"4.17"` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | The prefix to be added to all resources created by this solution. To skip using a prefix, set this value to null or an empty string. The prefix must begin with a lowercase letter and may contain only lowercase letters, digits, and hyphens '-'. It should not exceed 16 characters, must not end with a hyphen('-'), and can not contain consecutive hyphens ('--'). Example: `prod-0205-ocpqs`. | `string` | `"qs-da"` | no |
| <a name="input_region"></a> [region](#input\_region) | Region to provision all resources created by this example | `string` | `"au-syd"` | no |
| <a name="input_zone"></a> [zone](#input\_zone) | Specify the zone to which the cluster will be deployed. | `number` | `1` | no |

### Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
