variable "default_worker_pool_machine_type" {
  type        = string
  description = "The machine type for worker nodes. For AI addon installation machines should have atleast 8 vcpu, 32GB RAM and GPU. Refer this page for choosing [machine type](https://cloud.ibm.com/docs/openshift?topic=openshift-vpc-flavors)"
  default     = "bx2.8x32"
}

variable "default_worker_pool_workers_per_zone" {
  type        = number
  description = "Number of worker nodes in each zone of the cluster."
  default     = 2
  validation {
    condition     = var.default_worker_pool_workers_per_zone >= 2
    error_message = "OCP AI add-on requires at least 2 worker nodes in each worker pool."
  }
}

variable "default_worker_pool_operating_system" {
  type        = string
  description = "The operating system installed on the worker nodes."
  default     = "RHEL_9_64"
}

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
  description = "List of additional worker pools. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-ocp-ai/blob/main/solutions/fully-configurable/DA_docs.md#options-with-worker-pools)"
  default     = []
}
