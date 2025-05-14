locals {
  config_regex = "^.*?(\\d+)x(\\d+)"
  gpu_prefix   = ["gx2", "gx3", "gx4"]
}

# tflint-ignore: all
variable "prefix" {
  type        = string
  description = "The prefix to add to all resources that this solution creates (e.g `prod`, `test`, `dev`). To not use any prefix value, you can set this value to `null` or an empty string."
  nullable    = true
  validation {
    condition = (var.prefix == null ? true :
      alltrue([
        can(regex("^[a-z]{0,1}[-a-z0-9]{0,14}[a-z0-9]{0,1}$", var.prefix)),
        length(regexall("^.*--.*", var.prefix)) == 0
      ])
    )
    error_message = "Prefix must begin with a lowercase letter, contain only lowercase letters, numbers, and - characters. Prefixes must end with a lowercase letter or number and be 16 or fewer characters."
  }
}

# tflint-ignore: all
variable "existing_resource_group_name" {
  type        = string
  description = "The name of an existing resource group to provision the cluster."
  default     = "Default"
}

# tflint-ignore: all
variable "default_worker_pool_machine_type" {
  type        = string
  description = "Specifies the machine type for the default worker pool. This determines the CPU, memory, and disk resources available to each worker node. For OpenShift AI installation, machines should have atleast 8 vcpu, 32GB RAM and GPU. Refer [IBM Cloud documentation for available machine types](https://cloud.ibm.com/docs/openshift?topic=openshift-vpc-flavors)"
  default     = "bx2.8x32"

  # CPU validation
  validation {
    condition     = can(regex(local.config_regex, var.default_worker_pool_machine_type)) && tonumber(regex(local.config_regex, var.default_worker_pool_machine_type)[0]) >= 8
    error_message = "To install Red Hat OpenShift AI , all worker nodes in all pools must have at least 8-core CPU."
  }

  # RAM validation
  validation {
    condition     = can(regex(local.config_regex, var.default_worker_pool_machine_type)) && tonumber(regex(local.config_regex, var.default_worker_pool_machine_type)[1]) >= 32
    error_message = "To install Red Hat OpenShift AI, all worker nodes in all pools must have at least 32GB memory."
  }
}

# tflint-ignore: all
variable "default_worker_pool_workers_per_zone" {
  type        = number
  description = "Defines the number of worker nodes to provision in each zone for the default worker pool. Overall cluster must have at least 2 worker nodes, but individual worker pools may have fewer nodes per zone. [Learn More](https://cloud.ibm.com/docs/openshift?topic=openshift-ai-addon-install&interface=ui#ai-min)"
  default     = 2
}

# tflint-ignore: all
variable "default_worker_pool_operating_system" {
  type        = string
  description = "Provide the operating system for the worker nodes in the default worker pool. Ensure that the selected operating system is compatible with your AI framework and dependencies. Refer [here](https://cloud.ibm.com/docs/openshift?topic=openshift-openshift_versions) for supported Operating Systems"
  default     = "RHCOS"

  validation {
    condition     = contains(["REDHAT_8_64", "RHCOS", "RHEL_9_64"], var.default_worker_pool_operating_system)
    error_message = "Invalid operating system. Allowed values are: 'REDHAT_8_64', 'RHCOS', 'RHEL_9_64'."
  }
}

# tflint-ignore: all
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
      pool_name         = "gpu"
      machine_type      = "gx3.16x80.l4"
      workers_per_zone  = 1
      secondary_storage = "300gb.5iops-tier"
      operating_system  = "RHCOS"
    },
  ]

  # CPU validation
  validation {
    condition = alltrue([
      for pool in var.additional_worker_pools :
      can(regex(local.config_regex, pool.machine_type)) &&
      tonumber(regex(local.config_regex, pool.machine_type)[0]) >= 8
    ])
    error_message = "To install Red Hat OpenShift AI, all worker nodes in additional pools must have at least 8-core CPU."
  }

  # RAM validation
  validation {
    condition = alltrue([
      for pool in var.additional_worker_pools :
      can(regex(local.config_regex, pool.machine_type)) &&
      tonumber(regex(local.config_regex, pool.machine_type)[1]) >= 32
    ])
    error_message = "To install Red Hat OpenShift AI, all worker nodes in additional pools must have at least 32 GB RAM."
  }

  # Ensure atleast one GPU is present
  validation {
    condition     = contains(local.gpu_prefix, split(".", var.default_worker_pool_machine_type)[0]) || anytrue([for pool in var.additional_worker_pools : contains(local.gpu_prefix, split(".", pool.machine_type)[0])])
    error_message = "At least one worker pool (default or additional) must be GPU-enabled."
  }
}
