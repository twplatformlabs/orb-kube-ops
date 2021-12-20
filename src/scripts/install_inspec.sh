#!/bin/bash

function install() {
  echo "installing inspec ${1}"
  sudo gem install --no-document inspec-bin:${1}

}

function install_latest() {
  echo "installing inspec latest"
  sudo gem install --no-document inspec-bin
}

echo "requested inspec ${INSTALL_INSPEC_VERSION}"

if [[ $INSTALL_INSPEC_VERSION == "latest" ]]; then
  if [ "$(id -u)" = 0 ]; then
    install_latest
  else
    sudo bash -c "$(declare -f install_latest); install_latest;"
  fi
else
  if [ "$(id -u)" = 0 ]; then
    install ${INSTALL_INSPEC_VERSION}
  else
    sudo bash -c "$(declare -f install); install ${INSTALL_INSPEC_VERSION};"
  fi
fi

inspec version || { echo "error: invalid inspec version"; exit 2; }

