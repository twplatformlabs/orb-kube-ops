#!/bin/bash

function install() {
  echo "installing terraform ${1}"
  wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
  apt update && apt install terraform=${1}
}

function install_latest() {
  echo "installing terraform latest"
  wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
  apt update && apt install terraform
}

echo "requested terraform ${INSTALL_TERRAFORM_VERSION}"
echo "USE_SUDO = ${USE_SUDO}"

if [[ $INSTALL_TERRAFORM_VERSION == "latest" ]]; then
  if [ "$USE_SUDO" == 1 ]; then
    sudo bash -c "$(declare -f install_latest); install_latest;"
  else
    install_latest
  fi
else
  if [ "$USE_SUDO" == 1 ]; then
    sudo bash -c "$(declare -f install); install ${INSTALL_TERRAFORM_VERSION};"
  else
    install ${INSTALL_TERRAFORM_VERSION}
  fi
fi

terraform version || { echo "error: invalid terraform version"; exit 2; }
