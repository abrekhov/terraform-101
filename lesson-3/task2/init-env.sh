#!/bin/bash
export YC_FOLDER_ID=`yc config get folder-id`
export YC_CLOUD_ID=`yc config get cloud-id`
export YC_TOKEN=`yc iam create-token`
