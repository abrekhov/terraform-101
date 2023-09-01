resource "tls_private_key" "vm_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_sensitive_file" "vm_key_priv" {
  content  = tls_private_key.vm_key.private_key_openssh
  filename = "${path.module}/id_rsa"
}

resource "yandex_compute_instance" "vm" {
  name        = "vm"
  zone        = yandex_vpc_subnet.net-a.zone
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
    subnet_id = yandex_vpc_subnet.net-a.id
    nat       = true
  }
  metadata = {
    ssh-keys = "ubuntu:${trimspace(tls_private_key.vm_key.public_key_openssh)}"
  }

}
