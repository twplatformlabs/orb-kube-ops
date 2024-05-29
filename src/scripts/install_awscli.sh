#!/usr/bin/env bash
set -eo pipefail

function install() {
  echo "installing awscli ${1}"
  pip install awscli=="${1}"

}

function install_latest() {
  echo "installing awscli latest"
  pip install awscli
}

echo "requested awscli ${INSTALL_AWSCLI_VERSION}"
echo "USE_SUDO = ${USE_SUDO}"

if [[ "$INSTALL_AWSCLI_VERSION" == "latest" ]]; then
  if [ "$USE_SUDO" == "true"  ]; then
    sudo bash -c "$(declare -f install_latest); install_latest;"
  else
    install_latest
  fi
else
  if [ "$USE_SUDO" == "true"  ]; then
    sudo bash -c "$(declare -f install); install ${INSTALL_AWSCLI_VERSION};"
  else
    install "${INSTALL_AWSCLI_VERSION}"
  fi
fi

aws --version || { echo "error: invalid awscli version"; exit 2; }
