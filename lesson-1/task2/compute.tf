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
    cores         = var.cpu_count
    memory        = var.memory_count
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.net-a.id
  }
}
