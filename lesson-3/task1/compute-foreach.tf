resource "yandex_lockbox_secret" "ssh-private-keys" {
  name = "ssh-private-keys"
}

resource "tls_private_key" "zone_b_vms" {
  for_each = {
    for vm in var.zone_b_vms : vm.name => vm
  }
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "yandex_lockbox_secret_version" "ssh-private-keys-version" {
  secret_id = yandex_lockbox_secret.ssh-private-keys.id
  dynamic "entries" {
    for_each = var.zone_b_vms
    content {
      key        = "ssh-private-key-${entries.value.name}"
      text_value = tls_private_key.zone_b_vms[entries.value.name].private_key_openssh
    }
  }
}

resource "yandex_compute_instance" "vm_b_zone" {
  for_each = {
    for vm in var.zone_b_vms : vm.name => vm
  }
  name = each.value.name

  zone        = yandex_vpc_subnet.net-b.zone
  platform_id = "standard-v3"
  boot_disk {
    initialize_params {
      image_id = "alklr68luhjps75e9ov9" # yc compute image list --folder-id standard-images
      size     = 10
      type     = "network-ssd"
    }
  }
  resources {
    core_fraction = 100
    cores         = 2
    memory        = 4
  }
  network_interface {
    subnet_id  = yandex_vpc_subnet.net-b.id
    ip_address = each.value.ip
    nat        = each.value.nat
  }
  metadata = {
    ssh-keys = "ubuntu:${trimspace(tls_private_key.zone_b_vms[each.value.name].public_key_openssh)}"
  }

}
