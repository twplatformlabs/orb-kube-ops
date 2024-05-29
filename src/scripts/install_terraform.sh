#!/usr/bin/env bash
set -eo pipefail

function install() {
  echo "installing terraform ${1}"
  curl -SLO "https://releases.hashicorp.com/terraform/${1}/terraform_${1}_linux_amd64.zip" > "terraform_${1}_linux_amd64.zip"
  unzip "terraform_${1}_linux_amd64.zip" -d /usr/local/bin
}

echo "requested terraform ${INSTALL_TERRAFORM_VERSION}"
echo "USE_SUDO = ${USE_SUDO}"

if [[ "$INSTALL_TERRAFORM_VERSION" == "latest" ]]; then
  echo "install of 'latest' not supported"
  exit 1
else
  if [ "$USE_SUDO" == "true" ]; then
    sudo bash -c "$(declare -f install); install ${INSTALL_TERRAFORM_VERSION};"
  else
    install "${INSTALL_TERRAFORM_VERSION}"
  fi
fi

terraform version || { echo "error: invalid terraform version"; exit 2; }
