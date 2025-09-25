#!/usr/bin/env bash
set -eo pipefail

function install() {
  echo "installing karmada ${1}"
  curl -s https://raw.githubusercontent.com/karmada-io/karmada/master/hack/install-cli.sh | INSTALL_CLI_VERSION=${1} bash
}

echo "requested Karmada ${INSTALL_KARMADA_VERSION}"
echo "USE_SUDO = ${USE_SUDO}"

if [[ "$INSTALL_KARMADA_VERSION" == "latest" ]]; then
  echo "latest is not supported option"
  exit 1
fi

echo "preparing to install karmada ${VERSION}"

if [[ "$USE_SUDO" == "true" ]]; then
  sudo bash -c "$(declare -f install); install ${VERSION};"
else
  install "${VERSION}"
fi

karmada version || { echo "error: invalid karmada version"; exit 2; }


