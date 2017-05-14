#!/bin/bash

set -e -x


echo "Deploying to DEV PAAS"
img_tag=$(<web-version/number)
echo "Image version: "$img_tag


az login --service-principal -u "$service_principal_id" -p "$service_principal_secret" --tenant "$tenant_id"
az account set --subscription "$subscription_id"
az appservice web config container update -s dev -n $server_prefix-web-nodejs -g $paas_rg \
    --docker-registry-server-password $acr_password \
    --docker-registry-server-user $acr_username \
    --docker-registry-server-url $acr_endpoint \
    --docker-custom-image-name $acr_endpoint/ossdemo/web-nodejs:$img_tag

az appservice web config appsettings update --setting PORT=3000 -g $paas_rg -n $server_prefix-web-nodejs
az appservice web config appsettings update --setting API_ENDPOINT=http://${server_prefix}-api-nodejs-dev.azurewebsites.net -g $paas_rg -n $server_prefix-web-nodejs

echo "The WEB App is available here:${server_prefix}-web-nodejs-dev.azurewebsites.net"
