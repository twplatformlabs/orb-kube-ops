#!/usr/bin/env bash
set -eo pipefail

function install() {
  echo "installing trivy ${1}"
  curl -SLO "https://github.com/aquasecurity/trivy/releases/download/v${1}/trivy_${1}_Linux-64bit.tar.gz"
  tar -xzf "trivy_${1}_Linux-64bit.tar.gz"
  mv trivy /usr/local/bin/trivy
}

echo "requested trivy ${INSTALL_TRIVY_VERSION}"
echo "USE_SUDO = ${USE_SUDO}"

if [[ "$INSTALL_TRIVY_VERSION" == "latest" ]]; then
  echo "install of 'latest' not supported"
  exit 1
else
  if [ "$USE_SUDO" == "true" ]; then
    sudo bash -c "$(declare -f install); install ${INSTALL_TRIVY_VERSION};"
  else
    install "${INSTALL_TRIVY_VERSION}"
  fi
fi

trivy version || { echo "error: invalid trivy version"; exit 2; }
