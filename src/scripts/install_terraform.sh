#!/bin/bash

echo "requested terraform ${INSTALL_TERRAFORM_VERSION}"

curl -SLO "https://releases.hashicorp.com/terraform/${INSTALL_TERRAFORM_VERSION}/terraform_${INSTALL_TERRAFORM_VERSION}_linux_amd64.zip" > "terraform_${INSTALL_TERRAFORM_VERSION}_linux_amd64.zip"
sudo unzip "terraform_${INSTALL_TERRAFORM_VERSION}_linux_amd64.zip" -d /usr/local/bin
