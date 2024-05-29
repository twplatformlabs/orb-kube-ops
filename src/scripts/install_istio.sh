#!/usr/bin/env bash
set -eo pipefail

function install() {
  echo "installing istioctl ${1}"
  curl -L https://istio.io/downloadIstio  | ISTIO_VERSION="${1}" sh -
  mv -f "istio-${1}/bin/istioctl" /usr/local/bin/istioctl
}

echo "requested istioctl ${INSTALL_ISTIO_VERSION}"
echo "USE_SUDO = ${USE_SUDO}"

if [[ "$INSTALL_ISTIO_VERSION" == "latest" ]]; then
  echo "install of 'latest' not supported"
  exit 1
else
  if [ "$USE_SUDO" == "true" ]; then
    sudo bash -c "$(declare -f install); install ${INSTALL_ISTIO_VERSION};"
  else
    install "${INSTALL_ISTIO_VERSION}"
  fi
fi

istioctl version --short --remote=false || { echo "error: invalid istioctl version"; exit 2; }
