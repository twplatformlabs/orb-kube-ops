#!/usr/bin/env bash
set -eo pipefail

function install() {
  echo "installing checkov ${1}"
  pip install checkov=="${1}"

}

function install_latest() {
  echo "installing checkov latest"
  pip install checkov
}

echo "requested checkov ${INSTALL_CHECKOV_VERSION}"
echo "USE_SUDO = ${USE_SUDO}"

if [[ "$INSTALL_CHECKOV_VERSION" == "latest" ]]; then
  if [ "$USE_SUDO" == "true"  ]; then
    sudo bash -c "$(declare -f install_latest); install_latest;"
  else
    install_latest
  fi
else
  if [ "$USE_SUDO" == "true"  ]; then
    sudo bash -c "$(declare -f install); install ${INSTALL_CHECKOV_VERSION};"
  else
    install "${INSTALL_CHECKOV_VERSION}"
  fi
fi

checkov --version || { echo "error: invalid awscli version"; exit 2; }
