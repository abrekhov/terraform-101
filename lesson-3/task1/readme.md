# Loops

## Init (previous lesson setup)

```bash
yc iam service-account create --name sa-tf
```

```bash
export SA_ID=$(yc iam service-account get sa-tf --format json | jq -rMc '.id')
export FOLDER_ID=$(yc config get folder-id)
yc resource-manager folder add-access-binding $FOLDER_ID  --role admin --subject serviceAccount:$SA_ID
```

```bash
yc iam key create \
  --service-account-id $SA_ID \
  --folder-id $FOLDER_ID \
  --output key.json
```

```bash
. ./init-env.sh
```

Let's create S3 encypted bucket for storing terraform state.

```bash
yc iam service-account create --name sa-tf-state
export SA_ID=$(yc iam service-account get sa-tf-state --format json | jq -rMc '.id')
export FOLDER_ID=$(yc config get folder-id)
export TF_STATE_BUCKET=your-tf-bucket
yc storage bucket create --name $TF_STATE_BUCKET
yc kms symmetric-key create --name kms-tf-state --default-algorithm aes-256

#Switch on encryption on using created key
# https://console.il.nebius.com/folders/$FOLDER_ID/storage/buckets/$TF_STATE_BUCKET?section=encryption
```

Assign all needed roles to access bucket and apply changes in infrastructure.

```bash
yc resource-manager folder add-access-binding $FOLDER_ID  --role storage.uploader --subject serviceAccount:$SA_ID 
yc resource-manager folder add-access-binding $FOLDER_ID  --role storage.viewer --subject serviceAccount:$SA_ID 
yc resource-manager folder add-access-binding $FOLDER_ID  --role kms.keys.encrypterDecrypter --subject serviceAccount:$SA_ID 
yc resource-manager folder add-access-binding $FOLDER_ID  --role compute.admin --subject serviceAccount:$SA_ID 
yc resource-manager folder add-access-binding $FOLDER_ID  --role vpc.admin --subject serviceAccount:$SA_ID 
```

Set remote backend S3 as below:

```hcl
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"


  backend "s3" {
    endpoint         = "https://storage.il.nebius.cloud/"
    bucket           = "your-tf-bucket"
    key              = "terraform-state-prod/task1"
    region           = "il1"
    force_path_style = true

    # Remove AWS specific checks
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
  }
}
```

Create and export access key to reach the bucket.

```bash
yc iam access-key create --service-account-id $SA_ID --description "for storing the tf state" --format json | jq -rMc '. | "export AWS_ACCESS_KEY_ID=\(.access_key.key_id); export AWS_SECRET_ACCESS_KEY=\(.secret)" ' >> init-env.sh 
```

```bash
. ./init-env.sh

terraform init -migrate-state # optional. If you already had some local state
terraform init
terraform plan
```

## How to define value of the variable

BTW you can define variable values using (from high priority to lower):

1. TF_VAR_<varname> - env variable
1. from terraform.tfvars file
1. from terraform.tfvars.json file
1. from .auto.tfvars file
1. from .auto.tfvars.json file
1. -var or -var-file flag ( `terraform apply -var ...` or `terraform apply -var-file ...` )

## Loop using count

```hcl
# variables.tf
variable "vm_count" {
  type        = number
  description = "how many vms in zone a"
  default     = 2
}

# compute-count.tf
resource "yandex_compute_instance" "vm" {
  count       = var.vm_count
  name        = "vm-${count.index}"
  zone        = yandex_vpc_subnet.net-a.zone
  platform_id = "standard-v3"
  ...
  network_interface {
    subnet_id = yandex_vpc_subnet.net-a.id
    nat       = count.index == 0 ? true : false # an example of ternary operator
  }
  ...
}

# outputs.tf
output "count_internal_ip" {
  value = yandex_compute_instance.vm[*].network_interface[0].ip_address
}
output "count_external_ip" {
  value = yandex_compute_instance.vm[*].network_interface[0].nat_ip_address
}
```

## Loop using for_each

```hcl
# variables.tf
variable "zone_b_vms" {
  type = list(object({
    name = string
    ip   = string
    nat  = bool
  }))
  description = "list of vms"
}

# compute-foreach.tf
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
  dynamic "entries" { # using dynamic block for loop through all vms
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
  ...
}

# outputs.tf
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
```

## Apply, Check, Destroy

```bash
terraform apply -auto-approve
```

Check connection with created local key

```bash
ssh -i id_rsa_0 ubuntu@count_output_ip
```

Check connection with created lockbox key

```bash
cat > id_rsa_vm_three <<EOF
<paste private key from lockbox
EOF
chmod 400 id_rsa_vm_three
ssh -i id_rsa_vm_three ubuntu@count_output_ip
```

```bash
terraform destroy -auto-approve
```
