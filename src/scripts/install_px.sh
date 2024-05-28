#!/usr/bin/env bash
set -eo pipefail

function install() {
  echo "installing px ${1}"
  curl -o px "https://storage.googleapis.com/pixie-dev-public/cli/${1}/cli_linux_amd64"
  sudo chmod +x px
  mv px /uar/loca/bin/px
}

echo "requested px ${INSTALL_PX_VERSION}"
echo "USE_SUDO = ${USE_SUDO}"

if [[ "$INSTALL_CIRCLEPIPE_VERSION" == "latest" ]]; then
  echo "install tag latest not supported"
  exit 1
else
  if [ "$USE_SUDO" == 1 ]; then
    sudo bash -c "$(declare -f install); install ${INSTALL_PX_VERSION};"
  else
    install "${INSTALL_PX_VERSION}"
  fi
fi

px --version || { echo "error: invalid px version"; exit 2; }



