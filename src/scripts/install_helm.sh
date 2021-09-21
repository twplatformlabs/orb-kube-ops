#!/bin/bash

function install() {
  echo "installing helm ${1}"

}

function install_latest() {
  echo "installing helm latest"

}

echo "preparing to install helm ${VERSION}"

if [[ $INSTALL_HELM_VERSION == "latest" ]]; then
  if [ "$(id -u)" = 0 ]; then
    install_latest
  else
    sudo bash -c "$(declare -f install_latest); install_latest;"
  fi
else
  if [ "$(id -u)" = 0 ]; then
    install ${INSTALL_HELM_VERSION}
  else
    sudo bash -c "$(declare -f install); install ${INSTALL_HELM_VERSION};"
  fi
fi



kubectl version --client=true --short=true || { echo "error: invalid kubernetes version"; exit 2; }




VERIFY_CHECKSUM=false


  - when:
      condition: 
        equal: [ << parameters.helm-version >>, "latest" ]
      steps:
        - run:
            name: install latest version of helm
            command: |
              curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
              sudo bash -c "bash ./get_helm.sh"
  - when:
      and:
        - not:
            matches:
              pattern: "^latest$"
              value: << parameters.helm-version >>
        - not:
            matches:
              pattern: "^executor-version$"
              value: << parameters.helm-version >>
      steps:
        - run:
            name: install helm << parameters.helm-version >>
            command: |
              curl -SLO "https://get.helm.sh/helm-<< parameters.helm-version >>-linux-amd64.tar.gz"
              sudo tar -xf "helm-<< parameters.helm-version >>-linux-amd64.tar.gz"
              sudo mv -f linux-amd64/helm /usr/local/bin
