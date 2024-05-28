#!/usr/bin/env bash
set -eo pipefail

function install() {
  echo "installing circlepipe ${1}"
  curl -SLO https://github.com/ThoughtWorks-DPS/circlepipe/releases/download/${1}/circlepipe_Linux_amd64.tar.gz
  mkdir ./circlepipe
  tar -xzf circlepipe_Linux_amd64.tar.gz -C ./circlepipe
  mv ./circlepipe/circlepipe /usr/local/bin/circlepipe
  rm -rf ./circlepipe
}

echo "requested circlepipe ${INSTALL_CIRCLEPIPE_VERSION}"
echo "USE_SUDO = ${USE_SUDO}"

if [[ $INSTALL_CIRCLEPIPE_VERSION == "latest" ]]; then
  echo "install tag latest not supported"
  exit 1
else
  if [ "$USE_SUDO" == 1 ]; then
    sudo bash -c "$(declare -f install); install ${INSTALL_CIRCLEPIPE_VERSION};"
  else
    install ${INSTALL_CIRCLEPIPE_VERSION}
  fi
fi

circlepipe version || { echo "error: invalid kind version"; exit 2; }
