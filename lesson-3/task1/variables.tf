variable "vm_count" {
  type        = number
  description = "how many vms in zone a"
  default     = 2
}

variable "zone_b_vms" {
  type = list(object({
    name = string
    ip   = string
    nat  = bool
  }))
  description = "list of vms"
}
