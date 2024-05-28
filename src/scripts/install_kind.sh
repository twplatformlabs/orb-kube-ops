#!/usr/bin/env bash
set -eo pipefail

function install() {
  echo "installing kind ${1}"
  curl -Lo ./kind https://kind.sigs.k8s.io/dl/v${1}/kind-linux-amd64
  chmod +x ./kind
  mv ./kind /usr/local/bin/kind
}

function install_latest() {
  echo "installing kind latest"
  curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
  chmod +x ./kind
  mv ./kind /usr/local/bin/kind
}

echo "requested kind ${INSTALL_KIND_VERSION}"
echo "USE_SUDO = ${USE_SUDO}"

if [[ $INSTALL_KIND_VERSION == "latest" ]]; then
  if [ "$USE_SUDO" == 1 ]; then
    sudo bash -c "$(declare -f install_latest); install_latest;"
  else
    install_latest
  fi
else
  if [ "$USE_SUDO" == 1 ]; then
    sudo bash -c "$(declare -f install); install ${INSTALL_KIND_VERSION};"
  else
    install ${INSTALL_KIND_VERSION}
  fi
fi

kind version || { echo "error: invalid kind version"; exit 2; }
