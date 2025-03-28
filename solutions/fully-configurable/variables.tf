# tflint-ignore: all
variable "default_worker_pool_machine_type" {
  type        = string
  description = "Specifies the machine type for the default worker pool. This determines the CPU, memory, and disk resources available to each worker node. For Openshift AI installation, machines should have atleast 8 vcpu, 32GB RAM and GPU. Refer [IBM Cloud documentation for available machine types](https://cloud.ibm.com/docs/openshift?topic=openshift-vpc-flavors)"
  default     = "gx3.16x80.l4"
}

# tflint-ignore: all
variable "default_worker_pool_workers_per_zone" {
  type        = number
  description = "Defines the number of worker nodes to provision in each zone for the default worker pool. The cluster must have at least 2 worker nodes. [Learn More](https://cloud.ibm.com/docs/openshift?topic=openshift-ai-addon-install&interface=ui#ai-min)"
  default     = 2
  validation {
    condition     = var.default_worker_pool_workers_per_zone >= 2
    error_message = "OCP AI add-on requires at least 2 worker nodes in each worker pool."
  }
}

# tflint-ignore: all
variable "default_worker_pool_operating_system" {
  type        = string
  description = "Provide the operating system for the worker nodes in the default worker pool. Ensure that the selected operating system is compatible with your AI framework and dependencies. Refer [here](https://cloud.ibm.com/docs/openshift?topic=openshift-openshift_versions) for supported Operating Systems"
  default     = "RHEL_9_64"
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
    pool_name         = string
    machine_type      = string
    workers_per_zone  = number
    resource_group_id = optional(string)
    operating_system  = string
    labels            = optional(map(string))
    minSize           = optional(number)
    secondary_storage = optional(string)
    maxSize           = optional(number)
    enableAutoscaling = optional(bool)
    boot_volume_encryption_kms_config = optional(object({
      crk             = string
      kms_instance_id = string
      kms_account_id  = optional(string)
    }))
    additional_security_group_ids = optional(list(string))
  }))
  description = "List of additional worker pools with custom configurations to accommodate diverse AI workload requirements within the cluster. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-ocp-ai/blob/main/solutions/fully-configurable/DA_docs.md#options-with-worker-pools)"
  default = []
}
