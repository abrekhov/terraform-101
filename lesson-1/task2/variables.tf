variable "cpu_count" {
  type        = number
  description = "number of vcpu on VM"
  default     = 2
}

variable "memory_count" {
  type        = number
  description = "number of gigabytes of RAM on VM"
  default     = 4
}
