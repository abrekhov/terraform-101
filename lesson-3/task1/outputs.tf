output "count_internal_ip" {
  value = yandex_compute_instance.vm[*].network_interface[0].ip_address
}
output "count_external_ip" {
  value = yandex_compute_instance.vm[*].network_interface[0].nat_ip_address
}

output "for_each_internal_ip" {
  value = [
    for vm in var.zone_b_vms : yandex_compute_instance.vm_b_zone[vm.name].network_interface[0].ip_address
  ]
}
output "for_each_external_ip" {
  value = [
    for vm in var.zone_b_vms : yandex_compute_instance.vm_b_zone[vm.name].network_interface[0].nat_ip_address
  ]
}

