#!/usr/bin/env bash
set -eo pipefail

function install() {
  echo "installing awspec ${1}"
  gem install --no-document awspec:"${1}"

}

function install_latest() {
  echo "installing awspec latest"
  gem install --no-document awspec
}

echo "requested awspec ${INSTALL_AWSPEC_VERSION}"
echo "USE_SUDO = ${USE_SUDO}"

if [[ "$INSTALL_AWSPEC_VERSION" == "latest" ]]; then
  if [ "$USE_SUDO" == 1  ]; then
    sudo bash -c "$(declare -f install_latest); install_latest;"
  else
    install_latest
  fi
else
  if [ "$USE_SUDO" == 1  ]; then
    sudo bash -c "$(declare -f install); install ${INSTALL_AWSPEC_VERSION};"
  else
    install "${INSTALL_AWSPEC_VERSION}"
  fi
fi

awspec --version || { echo "error: invalid awspec version"; exit 2; }
