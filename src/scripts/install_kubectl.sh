#!/bin/bash

function install() {
  curl -LO "https://dl.k8s.io/release/$1/bin/linux/amd64/kubectl"
  chmod +x kubectl
  mv -f kubectl /usr/local/bin/kubectl
}

curl --version

if [[ "$KUBECTL_VERSION" == "latest" ]]; then
  VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
else
  VERSION=$KUBECTL_VERSION
fi

if [ "$(id -u)" = 0 ]; then
  install $VERSION
else
  sudo bash -c "$(declare -f install); install $VERSION;"
fi

kubectl version --client=true --short=true || { echo "error: invalid kubernetes version"; exit 2; }
