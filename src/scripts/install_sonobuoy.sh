#!/usr/bin/env bash
set -eo pipefail

function install() {
  echo "installing sonobuoy ${1}"
  curl -SLO "https://github.com/vmware-tanzu/sonobuoy/releases/download/v${1}/sonobuoy_${1}_linux_amd64.tar.gz"
  tar -xf "sonobuoy_${1}_linux_amd64.tar.gz"
  mv -f sonobuoy /usr/local/bin/sonobuoy
}

function install_latest() {
  echo "installing sonobuoy latest"
  export INSTALLED=$(curl -s https://api.github.com/repos/vmware-tanzu/sonobuoy/releases/latest | jq -r '.tag_name')
  curl -SLO "https://github.com/vmware-tanzu/sonobuoy/releases/download/$INSTALLED/sonobuoy_${INSTALLED:1}_linux_amd64.tar.gz"
  tar -xf "sonobuoy_${INSTALLED:1}_linux_amd64.tar.gz"
  mv -f sonobuoy /usr/local/bin/sonobuoy
}

echo "requested sonobuoy ${INSTALL_SONOBUOY_VERSION}"
echo "USE_SUDO = ${USE_SUDO}"

if [[ $INSTALL_SONOBUOY_VERSION == "latest" ]]; then
  if [[ "$USE_SUDO" == 1 ]]; then
    sudo bash -c "$(declare -f install_latest); install_latest;"
  else
    install_latest
  fi
else
  if [[ "$USE_SUDO" == 1 ]]; then
    sudo bash -c "$(declare -f install); install ${INSTALL_SONOBUOY_VERSION};"
  else
    install ${INSTALL_SONOBUOY_VERSION}
  fi
fi

sonobuoy version --short || { echo "error: invalid sonobuoy version"; exit 2; }
