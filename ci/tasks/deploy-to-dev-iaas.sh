#!/bin/bash

set -e

echo "Deploying to DEV PAAS"
img_tag=$(<web-version/number)
echo "Image version: "$img_tag

echo -e "Deploy containers via ansible to worker iaas servers..."
#change into the directory where the Ansible CFG is located

mkdir ~/.ssh
#Had to do this as the key is being read in one single line
printf "%s\n" "-----BEGIN RSA PRIVATE KEY-----" >> ~/.ssh/id_rsa
printf "%s\n" $server_ssh_private_key | tail -n +5 | head -n -4 >>  ~/.ssh/id_rsa
printf "%s" "-----END RSA PRIVATE KEY-----" >> ~/.ssh/id_rsa
echo $server_ssh_public_key >> ~/.ssh/id_rsa.pub
chmod 600 ~/.ssh/id_rsa*

web_repository=$acr_endpoint/ossdemo/web-nodejs:$img_tag
api_endpoint="http://dev-${server_prefix}.${location}.cloudapp.azure.com:81"
touch web-nodejs/ci/tasks/ansible/docker-hosts
printf "%s\n" "[dockerhosts]" >> web-nodejs/ci/tasks/ansible/docker-hosts
printf "%s\n" "dev-${server_prefix}.${server_location}.cloudapp.azure.com" >> web-nodejs/ci/tasks/ansible/docker-hosts
#printf "%s\n" "staging-${server_prefix}.${server_location}.cloudapp.azure.com" >> web-nodejs/ci/tasks/ansible/docker-hosts

sed -i -e "s@VALUEOF-DEMO-ADMIN-USER-NAME@${server_admin_username}@g" web-nodejs/ci/tasks/ansible/playbook-iaas-docker-deploy.yml
sed -i -e "s@VALUEOF-REGISTRY-SERVER-NAME@${acr_endpoint}@g" web-nodejs/ci/tasks/ansible/playbook-iaas-docker-deploy.yml
sed -i -e "s@VALUEOF-REGISTRY-USER-NAME@${acr_username}@g" web-nodejs/ci/tasks/ansible/playbook-iaas-docker-deploy.yml
sed -i -e "s@VALUEOF-REGISTRY-PASSWORD@${acr_password}@g" web-nodejs/ci/tasks/ansible/playbook-iaas-docker-deploy.yml
sed -i -e "s@VALUEOF-IMAGE-REPOSITORY@${web_repository}@g" web-nodejs/ci/tasks/ansible/playbook-iaas-docker-deploy.yml
sed -i -e "s@VALUEOF-API-ENDPOINT@${api_endpoint}@g" web-nodejs/ci/tasks/ansible/playbook-iaas-docker-deploy.yml
API_ENDPOINT=VALUEOF-API-ENDPOINT

cd web-nodejs/ci/tasks/ansible
 ansible-playbook -i docker-hosts playbook-iaas-docker-deploy.yml --private-key ~/.ssh/id_rsa
cd ..

echo -e ".you can now browse the application at http://dev-${server_prefix}.${server_location}.cloudapp.azure.com for individual servers."

