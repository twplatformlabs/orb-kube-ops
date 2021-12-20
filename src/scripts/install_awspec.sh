#!/bin/bash

function install() {
  echo "installing awspec ${1}"
  sudo gem install --no-document awspec:${1}

}

function install_latest() {
  echo "installing awspec latest"
  sudo gem install --no-document awspec
}

echo "requested awspec ${INSTALL_AWSPEC_VERSION}"

if [[ $INSTALL_AWSPEC_VERSION == "latest" ]]; then
  if [ "$(id -u)" = 0 ]; then
    install_latest
  else
    sudo bash -c "$(declare -f install_latest); install_latest;"
  fi
else
  if [ "$(id -u)" = 0 ]; then
    install ${INSTALL_AWSPEC_VERSION}
  else
    sudo bash -c "$(declare -f install); install ${INSTALL_AWSPEC_VERSION};"
  fi
fi

awspec version || { echo "error: invalid inspec version"; exit 2; }

             
