# Import existing state

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

## Demo

Create resources in web console of the Nebius cloud.

Define resourse in yout TF Configuration but leave breckets empty.

```bash
terraform import yandex_compute_instance.imported_vm <ID of VM> # import state
terraform state show yandex_compute_instance.imported_vm -no-color # show current state, copy n paste it to your configuration 

terraform plan  # remove all unconfigurable attributes
# ╷
# │ Error: Value for unconfigurable attribute
# │ 
# │   with yandex_compute_instance.imported_vm,
# │   on compute.tf line 36, in resource "yandex_compute_instance" "imported_vm":
# │   36:     index              = 0
# │ 
# │ Can't configure a value for "network_interface.0.index": its value will be decided automatically based on the result of
# │ applying this configuration.
```

Change copied configuration and apply changes

```bash
terraform apply -auto-approve
```
