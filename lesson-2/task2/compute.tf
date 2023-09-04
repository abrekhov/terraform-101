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
    memory        = 8
  }

  allow_stopping_for_update = true

  network_interface {
    subnet_id = yandex_vpc_subnet.net-a.id
    nat       = true
  }
  metadata = {
    ssh-keys = "ubuntu:${var.sshkey}"
  }

}
