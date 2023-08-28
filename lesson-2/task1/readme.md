# Terraform state

## Init

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

## Main

Let's create S3 encypted bucket for storing terraform state.

```bash
yc iam service-account create --name sa-tf-state
export SA_ID=$(yc iam service-account get sa-tf-state --format json | jq -rMc '.id')
export FOLDER_ID=$(yc config get folder-id)
yc storage bucket create --name your-new-bucket
yc kms symmetric-key create --name kms-tf-state --default-algorithm aes-256

#Switch on encryption on 
# https://console.il.nebius.com/folders/$FOLDER_ID/storage/buckets/$BUCKET?section=encryption
```

```bash
yc resource-manager folder add-access-binding $FOLDER_ID  --role storage.uploader --subject serviceAccount:$SA_ID 
yc resource-manager folder add-access-binding $FOLDER_ID  --role storage.viewer --subject serviceAccount:$SA_ID 
yc resource-manager folder add-access-binding $FOLDER_ID  --role kms.keys.encrypterDecrypter --subject serviceAccount:$SA_ID 

```


```bash
terraform init
terraform plan
terraform graph | dot -Tsvg > graph.svg
```

![DAG](./graph.svg)

```bash
terraform apply -auto-approve
```

```bash
terraform destroy -auto-approve
```
