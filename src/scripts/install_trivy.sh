#!/usr/bin/env bash
set -eo pipefail

function install() {
  echo "installing trivy ${1}"
  curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin "${1}"
}

echo "requested trivy ${INSTALL_TRIVY_VERSION}"
echo "USE_SUDO = ${USE_SUDO}"

# set to empty string if latest
if [[ "$INSTALL_TRIVY_VERSION" == "latest" ]]; then
  export INSTALL_TRIVY_VERSION=""
fi

if [ "$USE_SUDO" == "true" ]; then
  sudo bash -c "$(declare -f install); install ${INSTALL_TRIVY_VERSION};"
else
  install "${INSTALL_TRIVY_VERSION}"
fi

trivy version || { echo "error: invalid trivy version"; exit 2; }
