#!/bin/bash

function install() {
  echo "installing datadog ${1}"
  pip install --no-cache-dir --break-system-packages datadog==${1} 

}

function install_latest() {
  echo "installing datadog latest"
  pip install --no-cache-dir --break-system-packages datadog
}

echo "requested datadog ${INSTALL_DATADOG_VERSION}"
echo "USE_SUDO = ${USE_SUDO}"

if [[ $INSTALL_DATADOG_VERSION == "latest" ]]; then
  if [ "$USE_SUDO" == 1 ]; then
    sudo bash -c "$(declare -f install_latest); install_latest;"
  else
    install_latest
  fi
else
  if [ "$USE_SUDO" == 1 ]; then
    sudo bash -c "$(declare -f install); install ${INSTALL_DATADOG_VERSION};"
  else
    install ${INSTALL_DATADOG_VERSION}
  fi
fi

dog --version || { echo "error: invalid datadog version"; exit 2; }
