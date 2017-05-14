#!/bin/bash
set -e -x

echo "Deploying to DEV K8s"
img_tag=$(<web-version/number)
echo "Image version: "$img_tag

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

set +e
#Delete current deployment first
check=$(~/kubectl get deployment web-nodejs --namespace ossdemo-dev)
if [[ $check != *"NotFound"* ]]; then
  echo "Deleting existent deployment"
  result=$(eval ~/kubectl delete deployment web-nodejs --namespace ossdemo-dev)
  echo result 
fi

check=$(~/kubectl get svc web-nodejs --namespace ossdemo-dev)
if [[ $check != *"NotFound"* ]]; then
  echo "Deleting existent  service"
  result=$(eval ~/kubectl delete svc web-nodejs --namespace ossdemo-dev)
  echo result
fi

set -e

~/kubectl create -f web-nodejs/ci/tasks/k8s/web-deploy-dev.yml --namespace=ossdemo-dev
echo "Initial deployment & expose the service"
~/kubectl expose deployments web-nodejs --port=80 --target-port=3000 --type=LoadBalancer --name=web-nodejs --namespace=ossdemo-dev

externalIP="pending"
while [[ $externalIP == *"endin"*  ]]; do
  echo "Waiting for the service to get exposed..."
  sleep 30s
  line=$(~/kubectl get services --namespace ossdemo-dev | grep 'web-nodejs')
  IFS=' '
  read -r -a array <<< "$line"
  externalIP="${array[2]}"
done

echo "The WEB app is exposed on :$externalIP "
