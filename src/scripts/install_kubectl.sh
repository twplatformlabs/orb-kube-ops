#!/bin/bash

function install() {
  echo "installing kubectl ${1}"
  curl -LO "https://dl.k8s.io/release/$1/bin/linux/amd64/kubectl"
  chmod +x kubectl
  mv -f kubectl /usr/local/bin/kubectl
}

curl --version
echo "i asked it to deploy kubectl ${INSTALL_KUBECTL_VERSION}"

if [[ "$INSTALL_KUBECTL_VERSION" == "latest" ]]; then
echo "version = latest"
  VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
else
  echo "version is ${INSTALL_KUBECTL_VERSION}"
  VERSION=$INSTALL_KUBECTL_VERSION
fi

echo "preparing to install kubectl ${VERSION}"

if [ "$(id -u)" = 0 ]; then
  install ${VERSION}
else
  sudo bash -c "$(declare -f install); install ${VERSION};"
fi

kubectl version --client=true --short=true || { echo "error: invalid kubernetes version"; exit 2; }
