#!/bin/bash

function install() {
  echo "installing argocd ${1}"
  curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/download/v${1}/argocd-linux-amd64
  chmod +x argocd
  mv -f argocd /usr/local/bin/argocd
}

function install_latest() {
  echo "installing argocd latest"
  curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
  chmod +x argocd
  mv -f argocd /usr/local/bin/argocd
}

echo "requested argocd ${INSTALL_ARGOCD_VERSION}"
echo "USE_SUDO = ${USE_SUDO}"

if [[ $INSTALL_ARGOCD_VERSION == "latest" ]]; then
  if [ "$USE_SUDO" == 1 ]; then
    sudo bash -c "$(declare -f install_latest); install_latest;"
  else
    install_latest
  fi
else
  if [ "$USE_SUDO" == 1 ]; then
    sudo bash -c "$(declare -f install); install ${INSTALL_ARGOCD_VERSION};"
  else
    install ${INSTALL_ARGOCD_VERSION}
  fi
fi

argocd version --client || { echo "error: invalid argocd version"; exit 2; }
