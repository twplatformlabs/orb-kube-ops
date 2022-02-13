#!/bin/bash

function install() {
  echo "installing datadog ${1}"
  sudo pip install datadog==${1}

}

function install_latest() {
  echo "installing datadog latest"
  sudo pip install datadog
}

echo "requested datadog ${INSTALL_DATADOG_VERSION}"

if [[ $INSTALL_DATADOG_VERSION == "latest" ]]; then
  if [ "$(id -u)" = 0 ]; then
    install_latest
  else
    sudo bash -c "$(declare -f install_latest); install_latest;"
  fi
else
  if [ "$(id -u)" = 0 ]; then
    install ${INSTALL_DATADOG_VERSION}
  else
    sudo bash -c "$(declare -f install); install ${INSTALL_DATADOG_VERSION};"
  fi
fi

datadog --version || { echo "error: invalid datadog version"; exit 2; }
