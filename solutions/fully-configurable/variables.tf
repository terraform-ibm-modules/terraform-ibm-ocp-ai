# tflint-ignore: all
variable "default_worker_pool_machine_type" {
  type        = string
  description = "Specifies the machine type for the default worker pool. This determines the CPU, memory, and disk resources available to each worker node. For Openshift AI installation, machines should have atleast 8 vcpu, 32GB RAM and GPU. Refer [IBM Cloud documentation for available machine types](https://cloud.ibm.com/docs/openshift?topic=openshift-vpc-flavors)"
  default     = "gx3.16x80.l4"

  validation {
    condition     = startswith(var.default_worker_pool_machine_type, "gx2") || startswith(var.default_worker_pool_machine_type, "gx3") || startswith(var.default_worker_pool_machine_type, "gx4")
    error_message = "The machine type must be from the 'gx2', 'gx3', or 'gx4' series. Please choose a valid machine type with GPU support."
  }

  validation {
    condition     = tonumber(split("x", split(".", var.default_worker_pool_machine_type)[1])[0]) >= 8
    error_message = "To install Red Hat Openshift AI , all worker nodes in all pools must have at least 8-core CPU."
  }

  validation {
    condition     = tonumber(split("x", split(".", var.default_worker_pool_machine_type)[1])[1]) >= 32
    error_message = "To install Red Hat Openshift AI, all worker nodes in all pools must have at least 32GB memory."
  }
}

# tflint-ignore: all
variable "default_worker_pool_workers_per_zone" {
  type        = number
  description = "Defines the number of worker nodes to provision in each zone for the default worker pool. Overall cluster must have at least 2 worker nodes, but individual worker pools may have fewer nodes per zone. [Learn More](https://cloud.ibm.com/docs/openshift?topic=openshift-ai-addon-install&interface=ui#ai-min)"
  default     = 2
  validation {
    condition     = var.default_worker_pool_workers_per_zone >= 1
    error_message = "Each worker pool must have at least 1 worker node per zone."
  }
}

# tflint-ignore: all
variable "default_worker_pool_operating_system" {
  type        = string
  description = "Provide the operating system for the worker nodes in the default worker pool. Ensure that the selected operating system is compatible with your AI framework and dependencies. Refer [here](https://cloud.ibm.com/docs/openshift?topic=openshift-openshift_versions) for supported Operating Systems"
  default     = "RHEL_9_64"

  validation {
    condition     = contains(["REDHAT_8_64", "RHCOS", "RHEL_9_64"], var.default_worker_pool_operating_system)
    error_message = "Invalid operating system. Allowed values are: 'REDHAT_8_64', 'RHCOS', 'RHEL_9_64'."
  }
}

# tflint-ignore: all
variable "default_gpu_worker_pool_storage" {
  type        = string
  description = "Defines the storage configuration for GPU workloads in Red Hat OpenShift AI. This storage is critical for AI/ML workloads, ensuring optimal data processing and model training efficiency. [Learn More](https://cloud.ibm.com/docs/vpc?topic=vpc-block-storage-profiles&interface=ui#tiers)"
  default     = "300gb.5iops-tier"
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
  description = "List of additional worker pools with custom configurations to accommodate diverse AI workload requirements within the cluster. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-ocp-ai/blob/main/solutions/fully-configurable/DA_docs.md#options-with-worker-pools)"
  default     = []
}
