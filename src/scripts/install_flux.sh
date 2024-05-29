#!/usr/bin/env bash
set -eo pipefail

function install() {
  echo "installing flux ${1}"
  curl -s https://fluxcd.io/install.sh | FLUX_VERSION="${1}" bash
}

function install_latest() {
  echo "installing flux latest"
  curl -s https://fluxcd.io/install.sh | bash
}

echo "requested flux ${INSTALL_FLUX_VERSION}"
echo "USE_SUDO = ${USE_SUDO}"


if [[ "$INSTALL_FLUX_VERSION" == "latest" ]]; then
  if [ "$USE_SUDO" == "true"  ]; then
    sudo bash -c "$(declare -f install_latest); install_latest;"
  else
    install_latest
  fi
else
  if [ "$USE_SUDO" == "true"  ]; then
    sudo bash -c "$(declare -f install); install ${INSTALL_FLUX_VERSION};"
  else
    install "${INSTALL_FLUX_VERSION}"
  fi
fi

flux version --client || { echo "error: invalid flux version"; exit 2; }
