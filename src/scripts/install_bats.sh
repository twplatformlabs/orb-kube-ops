#!/usr/bin/env bash
set -eo pipefail

function install() {
  echo "installing bats ${1}"
  npm install -g bats@"${1}"

}

function install_latest() {
  echo "installing bats latest"
  npm install -g bats
}

echo "requested bats ${INSTALL_BATS_VERSION}"
echo "USE_SUDO = ${USE_SUDO}"

if [[ "$INSTALL_BATS_VERSION" == "latest" ]]; then
  if [ "$USE_SUDO" == 1 ]; then
    sudo bash -c "$(declare -f install_latest); install_latest;"
  else
    install_latest
  fi
else
  if [ "$USE_SUDO" == 1 ]; then
    sudo bash -c "$(declare -f install); install ${INSTALL_BATS_VERSION};"
  else
    install "${INSTALL_BATS_VERSION}"
  fi
fi

bats --version || { echo "error: invalid bats version"; exit 2; }
