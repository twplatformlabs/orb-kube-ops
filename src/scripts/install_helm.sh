#!/bin/bash

function install() {
  echo "installing helm ${1}"
  curl -SLO "https://get.helm.sh/helm-${1}-linux-amd64.tar.gz"
  sudo tar -xf "helm-${1}-linux-amd64.tar.gz"
  sudo mv -f linux-amd64/helm /usr/local/bin
}

function install_latest() {
  echo "installing helm latest"
  curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
  bash ./get_helm.sh
}

export INSTALL_KUBECTL_VERSION=${1}

if [[ $INSTALL_HELM_VERSION == "latest" ]]; then
  if [ "$(id -u)" = 0 ]; then
    install_latest
  else
    sudo bash -c "$(declare -f install_latest); install_latest;"
  fi
else
  if [ "$(id -u)" = 0 ]; then
    install ${INSTALL_HELM_VERSION}
  else
    sudo bash -c "$(declare -f install); install ${INSTALL_HELM_VERSION};"
  fi
fi

helm version || { echo "error: invalid helm version"; exit 2; }
