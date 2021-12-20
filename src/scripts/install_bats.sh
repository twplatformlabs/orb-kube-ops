#!/bin/bash

function install() {
  echo "installing bats ${1}"
  sudo npm install -g bats@${1}

}

function install_latest() {
  echo "installing bats latest"
  sudo npm install -g bats
}

echo "requested bats ${INSTALL_BATS_VERSION}"

if [[ $INSTALL_BATS_VERSION == "latest" ]]; then
  if [ "$(id -u)" = 0 ]; then
    install_latest
  else
    sudo bash -c "$(declare -f install_latest); install_latest;"
  fi
else
  if [ "$(id -u)" = 0 ]; then
    install ${INSTALL_BATS_VERSION}
  else
    sudo bash -c "$(declare -f install); install ${INSTALL_BATS_VERSION};"
  fi
fi

bats --version || { echo "error: invalid bats version"; exit 2; }
