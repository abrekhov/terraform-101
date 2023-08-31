terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"

  backend "s3" {
    endpoint         = "https://storage.il.nebius.cloud/"
    bucket           = "abrekhov-tf"
    key              = "terraform-state-prod/tf-state"
    region           = "il1"
    force_path_style = true

    # Remove AWS specific checks
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
  }
}

provider "yandex" {
  endpoint = "api.il.nebius.cloud:443"
  zone     = "il1-c"
}
