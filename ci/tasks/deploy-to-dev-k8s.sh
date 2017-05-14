#!/bin/bash

set -e

echo "Deploying to DEV K8s"
img_tag=$(<web-version/number)
echo "Image version: "$img_tag

#touch tag-out/rc_tag
#echo "1.0.1" >> tag-out/rc_tag
## Config the Docker Container
# 1-Login to Azure using the az command line

az login --service-principal -u "$service_principal_id" -p "$service_principal_secret" --tenant "$tenant_id"
az account set --subscription "$subscription_id"

az acs kubernetes install-cli --install-location ~/kubectl

mkdir ~/.ssh
#Had to do this as the key is being read in one single line
printf "%s\n" "-----BEGIN RSA PRIVATE KEY-----" >> ~/.ssh/id_rsa
printf "%s\n" $server_ssh_private_key | tail -n +5 | head -n -4 >>  ~/.ssh/id_rsa
printf "%s" "-----END RSA PRIVATE KEY-----" >> ~/.ssh/id_rsa
echo $server_ssh_public_key >> ~/.ssh/id_rsa.pub
chmod 600 ~/.ssh/id_rsa*

web_repository=$acr_endpoint/ossdemo/web-nodejs:$img_tag

az acs kubernetes get-credentials --resource-group=$acs_rg --name k8s-$server_prefix
echo "create secret to login to the private registry"

sed -i -e "s@WEB-NODEJS-REPOSITORY@${web_repository}@g" web-nodejs/ci/tasks/k8s/web-deploy-dev.yml

#Delete current deployment first
check=$(~/kubectl get deployment -l app=web-nodejs,env=dev)
if [[ $check != *"NotFound"* ]]; then
  echo "Deleting existent deployment"
  ~/kubectl delete deployment -l app=web-nodejs,env=dev
  ~/kubectl delete svc -l app=web-nodejs,env=dev 
fi

~/kubectl create -f web-nodejs/ci/tasks/k8s/web-deploy-dev.yml
echo "Initial deployment & expose the service"
~/kubectl expose deployments web-nodejs --port=80 --target-port=3001 --type=LoadBalancer --name=web-nodejs

externalIP="pending"
while [[ $externalIP == *"endin"*  ]]; do
  echo "Waiting for the service to get exposed..."
  sleep 30s
  line=$(~/kubectl get services | grep 'web-nodejs')
  IFS=' '
  read -r -a array <<< "$line"
  externalIP="${array[2]}"
done

echo "The WEB app is exposed on :$externalIP "
