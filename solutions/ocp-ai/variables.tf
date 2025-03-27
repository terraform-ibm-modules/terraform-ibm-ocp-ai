variable "default_worker_pool_machine_type" {
  type        = string
  description = "The machine type for worker nodes."
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
