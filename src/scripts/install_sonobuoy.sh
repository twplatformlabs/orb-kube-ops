#!/bin/bash

function install() {
  echo "installing sonobuoy ${1}"
  curl -SLO "https://github.com/vmware-tanzu/sonobuoy/releases/download/v${1}/sonobuoy_${1}_linux_amd64.tar.gz"
  sudo tar -xf "sonobuoy_${1}_linux_amd64.tar.gz"
  sudo mv -f sonobuoy /usr/local/bin/sonobuoy
}

function install_latest() {
  echo "installing sonobuoy latest"
  export INSTALLED=$(curl -s https://api.github.com/repos/vmware-tanzu/sonobuoy/releases/latest | jq -r '.tag_name')
  curl -SLO "https://github.com/vmware-tanzu/sonobuoy/releases/download/$INSTALLED/sonobuoy_${INSTALLED:1}_linux_amd64.tar.gz"
  sudo tar -xf "sonobuoy_${INSTALLED:1}_linux_amd64.tar.gz"
  sudo mv -f sonobuoy /usr/local/bin/sonobuoy
}

echo "requested sonobuoy ${INSTALL_SONOBUOY_VERSION}"

if [[ $INSTALL_SONOBUOY_VERSION == "latest" ]]; then
  if [ "$(id -u)" = 0 ]; then
    install_latest
  else
    sudo bash -c "$(declare -f install_latest); install_latest;"
  fi
else
  if [ "$(id -u)" = 0 ]; then
    install ${INSTALL_SONOBUOY_VERSION}
  else
    sudo bash -c "$(declare -f install); install ${INSTALL_SONOBUOY_VERSION};"
  fi
fi

sonobuoy version --short || { echo "error: invalid sonobuoy version"; exit 2; }

