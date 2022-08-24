#!/bin/bash

function install() {
  echo "installing kubectl ${1}"
  curl -LO "https://dl.k8s.io/release/$1/bin/linux/amd64/kubectl"
  chmod +x kubectl
  mv -f kubectl /usr/local/bin/kubectl
}

echo "requested kubectl ${INSTALL_KUBECTL_VERSION}"
echo "USE_SUDO = ${USE_SUDO}"

if [[ "$INSTALL_KUBECTL_VERSION" == "latest" ]]; then
echo "version = latest"
  VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
else
  echo "version is ${INSTALL_KUBECTL_VERSION}"
  VERSION=v$INSTALL_KUBECTL_VERSION
fi

echo "preparing to install kubectl ${VERSION}"

if [[ "$USE_SUDO" == 1 ]]; then
  sudo bash -c "$(declare -f install); install ${VERSION};"
else
  install ${VERSION}
fi

kubectl version --client=true --short=true || { echo "error: invalid kubectl version"; exit 2; }
