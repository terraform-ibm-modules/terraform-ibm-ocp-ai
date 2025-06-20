locals {
  config_regex  = "^.*?(\\d+)x(\\d+)"
  gpu_prefix    = ["gx2", "gx3", "gx4"]
  machine_regex = "^[a-z0-9]+(?:\\.[a-z0-9]+)*\\.\\d+x\\d+(?:\\.[a-z0-9]+)?$"
}
variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud API key."
  sensitive   = true
}
variable "existing_resource_group_name" {
  type        = string
  description = "Name of the existing resource group.  Required if not creating new resource group"
  default     = "Default"
}
variable "prefix" {
  type        = string
  description = "The prefix to be added to all resources created by this solution. To skip using a prefix, set this value to null or an empty string. The prefix must begin with a lowercase letter and may contain only lowercase letters, digits, and hyphens '-'. It should not exceed 16 characters, must not end with a hyphen('-'), and can not contain consecutive hyphens ('--'). Example: `prod-0205-ocpqs`."
  nullable    = true
  validation {
    condition = (var.prefix == null || var.prefix == "" ? true :
      alltrue([
        can(regex("^[a-z][-a-z0-9]*[a-z0-9]$", var.prefix)),
        length(regexall("--", var.prefix)) == 0
      ])
    )
    error_message = "Prefix must begin with a lowercase letter and may contain only lowercase letters, digits, and hyphens '-'. It must not end with a hyphen('-'), and cannot contain consecutive hyphens ('--')."
  }
  validation {
    condition     = length(var.prefix) <= 16
    error_message = "Prefix must not exceed 16 characters."
  }
}
variable "region" {
  type        = string
  description = "Region to provision all resources created by this example"
  default     = "au-syd"
}
variable "ocp_version" {
  type        = string
  description = "The version of the OpenShift cluster."
  default     = "4.17"
}
variable "cluster_name" {
  type        = string
  description = "Name of new IBM Cloud OpenShift Cluster"
  default     = "ocp-ai"
}
variable "address_prefix" {
  description = "The IP range that will be defined for the VPC for a certain location. Use only with manual address prefixes."
  type        = string
  default     = "10.245.0.0/24"
}

variable "ocp_entitlement" {
  type        = string
  description = "Value that is applied to the entitlements for OCP cluster provisioning"
  default     = null
}
variable "zone" {
  type        = number
  description = "Specify the zone to which the cluster will be deployed."
  default     = 1
  validation {
    condition     = contains([1, 2, 3], var.zone)
    error_message = "Each region has only 3 zones."
  }
}
variable "default_worker_pool_machine_type" {
  type        = string
  description = "Specifies the machine type for the default worker pool. This determines the CPU, memory, and disk resources available to each worker node. For OpenShift AI installation, machines should have atleast 8 vcpu, 32GB RAM and GPU. Refer [IBM Cloud documentation for available machine types](https://cloud.ibm.com/docs/openshift?topic=openshift-vpc-flavors)"
  default     = "bx2.8x32"

  # Validate machine type
  validation {
    condition     = length(regexall(local.machine_regex, var.default_worker_pool_machine_type)) > 0
    error_message = "Invalid value provided for the machine type."
  }

  # CPU validation
  validation {
    condition     = tonumber(regex(local.config_regex, var.default_worker_pool_machine_type)[0]) >= 8
    error_message = "To install Red Hat OpenShift AI , all worker nodes in all pools must have at least 8-core CPU."
  }

  # RAM validation
  validation {
    condition     = tonumber(regex(local.config_regex, var.default_worker_pool_machine_type)[1]) >= 32
    error_message = "To install Red Hat OpenShift AI, all worker nodes in all pools must have at least 32GB memory."
  }
}

#tflint-ignore: all
variable "default_worker_pool_workers_per_zone" {
  type        = number
  description = "Defines the number of worker nodes to provision in each zone for the default worker pool. Overall cluster must have at least 2 worker nodes, but individual worker pools may have fewer nodes per zone. [Learn More](https://cloud.ibm.com/docs/openshift?topic=openshift-ai-addon-install&interface=ui#ai-min)"
  default     = 2
}

# tflint-ignore: all
variable "default_worker_pool_operating_system" {
  type        = string
  description = "Provide the operating system for the worker nodes in the default worker pool. [Learn more](https://cloud.ibm.com/docs/openshift?topic=openshift-ai-addon-install&interface=ui#ai-min)"
  default     = "RHCOS"
  validation {
    condition     = contains(["REDHAT_8_64", "RHCOS", "RHEL_9_64"], var.default_worker_pool_operating_system)
    error_message = "Invalid operating system. Allowed values are: 'REDHAT_8_64', 'RHCOS', 'RHEL_9_64'."
  }
}
variable "access_tags" {
  type        = list(string)
  description = "A list of access tags to apply to the resources created by the module."
  default     = []
}
variable "manage_all_addons" {
  type        = bool
  default     = false
  nullable    = false # null values are set to default value
  description = "Instructs Terraform to manage all cluster addons, even if addons were installed outside of the module. If set to 'true' this module destroys any addons that were installed by other sources."
}
variable "addons" {
  type = object({
    openshift-ai = optional(object({
      version         = optional(string)
      parameters_json = optional(string)
    }))
  })
  description = "Map of OCP cluster add-on versions to install (NOTE: The 'vpc-block-csi-driver' add-on is installed by default for VPC clusters and 'ibm-storage-operator' is installed by default in OCP 4.15 and later, however you can explicitly specify it here if you wish to choose a later version than the default one). For full list of all supported add-ons and versions, see https://cloud.ibm.com/docs/containers?topic=containers-supported-cluster-addon-versions. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-ocp-virtualization/blob/main/solutions/quickstart/DA_docs.md#options-with-addons)"
  nullable    = false
  default = {
    openshift-ai = {
      version = "416"
    }
  }
}
variable "additional_worker_pools" {
  type = list(object({
    vpc_subnets = optional(list(object({
      id         = string
      zone       = string
      cidr_block = string
    })), [])
    pool_name                     = string
    machine_type                  = string
    workers_per_zone              = number
    operating_system              = string
    labels                        = optional(map(string))
    minSize                       = optional(number)
    secondary_storage             = optional(string)
    maxSize                       = optional(number)
    enableAutoscaling             = optional(bool)
    additional_security_group_ids = optional(list(string))
  }))
  description = "List of additional worker pools configured exclusively for the GPU machine type to support AI workload requirements within the cluster. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-ocp-ai/blob/main/solutions/fully-configurable/DA_docs.md#options-with-worker-pools)"
  default = [
    {
      pool_name        = "gpu-2"
      machine_type     = "gx3.16x80.l4"
      workers_per_zone = 2
      operating_system = "RHCOS"
    },
  ]

  # Machine Type

  validation {
    condition     = alltrue([for pool in var.additional_worker_pools : length(regexall(local.machine_regex, pool.machine_type)) > 0])
    error_message = "Invalid value provided for the machine type."
  }

  # CPU validation
  validation {
    condition     = alltrue([for pool in var.additional_worker_pools : tonumber(regex(local.config_regex, pool.machine_type)[0]) >= 8])
    error_message = "To install Red Hat OpenShift AI, all worker nodes in additional pools must have at least 8-core CPU."
  }

  # RAM validation
  validation {
    condition     = alltrue([for pool in var.additional_worker_pools : tonumber(regex(local.config_regex, pool.machine_type)[1]) >= 32])
    error_message = "To install Red Hat OpenShift AI, all worker nodes in additional pools must have at least 32 GB RAM."
  }

  #Ensure atleast one GPU is present
  validation {
    condition     = contains(local.gpu_prefix, split(".", var.default_worker_pool_machine_type)[0]) || anytrue([for pool in var.additional_worker_pools : contains(local.gpu_prefix, split(".", pool.machine_type)[0])])
    error_message = "At least one worker pool (default or additional) must be GPU-enabled."
  }

  # Operating System validation
  validation {
    condition = alltrue([
      for pool in var.additional_worker_pools : contains(["REDHAT_8_64", "RHCOS", "RHEL_9_64"], pool.operating_system)
    ])
    error_message = "Additional worker pool must specify a valid operating system. Allowed values are :  'REDHAT_8_64', 'RHCOS', or 'RHEL_9_64'."
  }
}
