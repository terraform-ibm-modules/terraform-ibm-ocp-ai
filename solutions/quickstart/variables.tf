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
  description = "The name of an existing resource group to provision the resources. If not provided the default resource group will be used."
  default     = null
}
variable "provider_visibility" {
  description = "Set the visibility value for the IBM terraform provider. [Learn more](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/guides/custom-service-endpoints)."
  type        = string
  default     = "private"

  validation {
    condition     = contains(["public", "private", "public-and-private"], var.provider_visibility)
    error_message = "Invalid visibility option. Allowed values are 'public', 'private', or 'public-and-private'."
  }
}
variable "prefix" {
  type        = string
  nullable    = true
  description = "The prefix to add to all resources that this solution creates (e.g `prod`, `test`, `dev`). To skip using a prefix, set this value to `null` or an empty string. [Learn more](https://terraform-ibm-modules.github.io/documentation/#/prefix.md)."

  validation {
    # - null and empty string is allowed
    # - Must not contain consecutive hyphens (--): length(regexall("--", var.prefix)) == 0
    # - Starts with a lowercase letter: [a-z]
    # - Contains only lowercase letters (a–z), digits (0–9), and hyphens (-)
    # - Must not end with a hyphen (-): [a-z0-9]
    condition = (var.prefix == null || var.prefix == "" ? true :
      alltrue([
        can(regex("^[a-z][-a-z0-9]*[a-z0-9]$", var.prefix)),
        length(regexall("--", var.prefix)) == 0
      ])
    )
    error_message = "Prefix must begin with a lowercase letter and may contain only lowercase letters, digits, and hyphens '-'. It must not end with a hyphen('-'), and cannot contain consecutive hyphens ('--')."
  }

  validation {
    # must not exceed 16 characters in length
    condition     = var.prefix == null || var.prefix == "" ? true : length(var.prefix) <= 16
    error_message = "Prefix must not exceed 16 characters."
  }
}

variable "region" {
  type        = string
  description = "Region in which all the resources will be deployed. [Learn More](https://terraform-ibm-modules.github.io/documentation/#/region)."
  default     = "jp-tok"
}
variable "openshift_version" {
  type        = string
  description = "The version of the OpenShift cluster. Any add-on versions specified in the `addons` input must be compatible with the selected OpenShift cluster version."
  default     = "4.19"
}
variable "cluster_name" {
  type        = string
  description = "Name of new IBM Cloud OpenShift Cluster"
  default     = "ocp-ai"
}
variable "address_prefix" {
  description = "The IP range that will be defined for the VPC for a certain location. Use only with manual address prefixes."
  type        = string
  default     = "10.10.10.0/24"
}

variable "ocp_entitlement" {
  type        = string
  description = "Value that is applied to the entitlements for OCP cluster provisioning"
  default     = null
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

variable "default_worker_pool_workers_per_zone" {
  type        = number
  description = "Defines the number of worker nodes to provision in each zone for the default worker pool. Overall cluster must have at least 2 worker nodes, but individual worker pools may have fewer nodes per zone. [Learn More](https://cloud.ibm.com/docs/openshift?topic=openshift-ai-addon-install&interface=ui#ai-min)"
  default     = 2
}

variable "default_worker_pool_operating_system" {
  type        = string
  description = "Provide the operating system for the worker nodes in the default worker pool. [Learn more](https://cloud.ibm.com/docs/openshift?topic=openshift-ai-addon-install&interface=ui#ai-min)"
  default     = "RHCOS"
  validation {
    condition     = contains(["REDHAT_8_64", "RHCOS", "RHEL_9_64"], var.default_worker_pool_operating_system)
    error_message = "Invalid operating system. Allowed values are: 'REDHAT_8_64', 'RHCOS', 'RHEL_9_64'."
  }
  validation {
    condition     = tonumber(var.openshift_version) < 4.18 || var.default_worker_pool_operating_system == "RHCOS"
    error_message = "Invalid operating system. For OpenShift version 4.18 or higher, the worker node operating system must be 'RHCOS'. [Learn more](https://cloud.ibm.com/docs/openshift?topic=openshift-ai-addon-install&interface=ui#ai-min)"
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
  description = "Map of OCP cluster add-on versions to install for Openshift AI. For full list of all supported versions for Openshift AI, see https://cloud.ibm.com/docs/containers?topic=containers-supported-cluster-addon-versions. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-ocp-ai/blob/main/solutions/quickstart/DA_docs.md)"
  nullable    = false
  default = {
    openshift-ai = {
      version = "418"
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
  description = "List of additional worker pools configured exclusively for the GPU machine type to support AI workload requirements within the cluster. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-ocp-ai/blob/main/solutions/quickstart/DA_docs.md#options-with-worker-pools)"
  default = [
    {
      pool_name         = "gpu"
      machine_type      = "gx3.16x80.l4"
      workers_per_zone  = 1
      operating_system  = "RHCOS"
      secondary_storage = "300gb.5iops-tier"
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

  validation {
    condition = alltrue([
      for pool in var.additional_worker_pools : tonumber(var.openshift_version) < 4.18 || pool.operating_system == "RHCOS"
    ])
    error_message = "Invalid operating system. For OpenShift version 4.18 or higher, the worker node operating system must be 'RHCOS'. [Learn more](https://cloud.ibm.com/docs/openshift?topic=openshift-ai-addon-install&interface=ui#ai-min)"
  }
}
