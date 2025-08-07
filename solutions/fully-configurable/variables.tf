locals {
  config_regex  = "^.*?(\\d+)x(\\d+)"
  gpu_prefix    = ["gx2", "gx3", "gx4"]
  machine_regex = "^[a-z0-9]+(?:\\.[a-z0-9]+)*\\.\\d+x\\d+(?:\\.[a-z0-9]+)?$"
}

# tflint-ignore: all
variable "prefix" {
  type        = string
  nullable    = true
  description = "The prefix to be added to all resources created by this solution. To skip using a prefix, set this value to null or an empty string. The prefix must begin with a lowercase letter and may contain only lowercase letters, digits, and hyphens '-'. It should not exceed 16 characters, must not end with a hyphen('-'), and can not contain consecutive hyphens ('--'). Example: prod-0205-ocpai. [Learn more](https://terraform-ibm-modules.github.io/documentation/#/prefix.md)."

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


# tflint-ignore: all
variable "existing_resource_group_name" {
  type        = string
  description = "The name of an existing resource group to provision the cluster."
  default     = "Default"
}

# tflint-ignore: all
variable "ocp_version" {
  type        = string
  description = "Version of the OCP cluster to provision."
  default     = "4.17"
}

# tflint-ignore: all
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
    error_message = "To install Red Hat OpenShift AI add-on , all worker nodes in all pools must have at least 8-core CPU."
  }

  # RAM validation
  validation {
    condition     = tonumber(regex(local.config_regex, var.default_worker_pool_machine_type)[1]) >= 32
    error_message = "To install Red Hat OpenShift AI add-on, all worker nodes in all pools must have at least 32GB memory."
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
  description = "Provide the operating system for the worker nodes in the default worker pool. [Learn more](https://cloud.ibm.com/docs/openshift?topic=openshift-ai-addon-install&interface=ui#ai-min)"
  default     = "RHCOS"
  validation {
    condition     = contains(["REDHAT_8_64", "RHCOS", "RHEL_9_64"], var.default_worker_pool_operating_system)
    error_message = "Invalid operating system. Allowed values are: 'REDHAT_8_64', 'RHCOS', 'RHEL_9_64'."
  }
  validation {
    condition     = tonumber(var.ocp_version) < 4.18 || var.default_worker_pool_operating_system == "RHCOS"
    error_message = "Invalid operating system. For OpenShift version 4.18 or higher, the worker node operating system must be 'RHCOS'. [Learn more](https://cloud.ibm.com/docs/openshift?topic=openshift-ai-addon-install&interface=ui#ai-min)"
  }
}

# tflint-ignore: all
variable "subnets" {
  description = "List of subnets for the VPC. For each item in each array, a subnet will be created. Items can be either CIDR blocks or total ipv4 addressess. Public gateways will be enabled only in zones where a gateway has been created. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vpc/blob/main/solutions/fully-configurable/DA-types.md#subnets-)."
  type = object({
    zone-1 = list(object({
      name           = string
      cidr           = string
      public_gateway = optional(bool)
      acl_name       = string
      no_addr_prefix = optional(bool, false) # do not automatically add address prefix for subnet, overrides other conditions if set to true
      subnet_tags    = optional(list(string), [])
    }))
    zone-2 = optional(list(object({
      name           = string
      cidr           = string
      public_gateway = optional(bool)
      acl_name       = string
      no_addr_prefix = optional(bool, false) # do not automatically add address prefix for subnet, overrides other conditions if set to true
      subnet_tags    = optional(list(string), [])
    })))
    zone-3 = optional(list(object({
      name           = string
      cidr           = string
      public_gateway = optional(bool)
      acl_name       = string
      no_addr_prefix = optional(bool, false) # do not automatically add address prefix for subnet, overrides other conditions if set to true
      subnet_tags    = optional(list(string), [])
    })))
  })

  default = {
    zone-1 = [
      {
        name           = "subnet-a"
        cidr           = "10.10.10.0/24"
        public_gateway = true
        acl_name       = "vpc-acl"
        no_addr_prefix = false
      }
    ],
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

  # Machine Type

  validation {
    condition     = alltrue([for pool in var.additional_worker_pools : length(regexall(local.machine_regex, pool.machine_type)) > 0])
    error_message = "Invalid value provided for the machine type."
  }

  # CPU validation
  validation {
    condition     = alltrue([for pool in var.additional_worker_pools : tonumber(regex(local.config_regex, pool.machine_type)[0]) >= 8])
    error_message = "To install Red Hat OpenShift AI add-on, all worker nodes in additional pools must have at least 8-core CPU."
  }

  # RAM validation
  validation {
    condition     = alltrue([for pool in var.additional_worker_pools : tonumber(regex(local.config_regex, pool.machine_type)[1]) >= 32])
    error_message = "To install Red Hat OpenShift AI add-on, all worker nodes in additional pools must have at least 32 GB RAM."
  }

  # Ensure atleast one GPU is present
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
      for pool in var.additional_worker_pools : tonumber(var.ocp_version) < 4.18 || pool.operating_system == "RHCOS"
    ])
    error_message = "Invalid operating system. For OpenShift version 4.18 or higher, the worker node operating system must be 'RHCOS'. [Learn more](https://cloud.ibm.com/docs/openshift?topic=openshift-ai-addon-install&interface=ui#ai-min)"
  }
}
