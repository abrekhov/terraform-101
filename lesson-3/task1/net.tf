resource "yandex_vpc_network" "network" {
  name = "network"
}

resource "yandex_vpc_subnet" "net-a" {
  name           = "net-a"
  zone           = "il1-a"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["10.0.10.0/24"]
}


resource "yandex_vpc_subnet" "net-b" {
  name           = "net-b"
  zone           = "il1-b"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["10.0.20.0/24"]
}

resource "yandex_vpc_subnet" "net-c" {
  name           = "net-c"
  zone           = "il1-c"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["10.0.30.0/24"]
}

