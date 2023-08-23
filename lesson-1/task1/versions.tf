terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  endpoint = "api.il.nebius.cloud:443"
  zone     = "il1-c"
}
