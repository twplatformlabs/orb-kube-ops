#!/usr/bin/env bash
set -eo pipefail

function deps() {
  export RUBYOPT='-raws-sdk-elastictranscoder'
  sudo gem install  --no-document \
           base64:0.1.0 \
           aws-sdk \
           aws-sdk-elastictranscoder
}

function install() {
  echo "installing awspec ${1}"
  deps
  gem install --no-document awspec:"${1}"

}

function install_latest() {
  echo "installing awspec latest"
  deps
  gem install --no-document awspec
}

echo "requested awspec ${INSTALL_AWSPEC_VERSION}"
echo "USE_SUDO = ${USE_SUDO}"

if [[ "$INSTALL_AWSPEC_VERSION" == "latest" ]]; then
  if [ "$USE_SUDO" == "true"  ]; then
    sudo bash -c "$(declare -f install_latest); install_latest;"
  else
    install_latest
  fi
else
  if [ "$USE_SUDO" == "true"  ]; then
    sudo bash -c "$(declare -f install); install ${INSTALL_AWSPEC_VERSION};"
  else
    install "${INSTALL_AWSPEC_VERSION}"
  fi
fi

awspec --version || { echo "error: invalid awspec version"; exit 2; }
