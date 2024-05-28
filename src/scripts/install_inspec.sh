#!/usr/bin/env bash
set -eo pipefail

function install() {
  echo "installing inspec ${1}"
  gem install --no-document inspec-bin:"${1}"

}

function install_latest() {
  echo "installing inspec latest"
  gem install --no-document inspec-bin
}

echo "requested inspec ${INSTALL_INSPEC_VERSION}"
echo "USE_SUDO = ${USE_SUDO}"

if [[ "$INSTALL_INSPEC_VERSION" == "latest" ]]; then
  if [ "$USE_SUDO" == 1 ]; then
    sudo bash -c "$(declare -f install_latest); install_latest;"
  else
    install_latest
  fi
else
  if [ "$USE_SUDO" == 1 ]; then
    sudo bash -c "$(declare -f install); install ${INSTALL_INSPEC_VERSION};"
  else
    install "${INSTALL_INSPEC_VERSION}"
  fi
fi

inspec version || { echo "error: invalid inspec version"; exit 2; }
