#!/bin/bash

echo "requested kubectl ${INSTALL_ISTIOCTL_VERSION}"

curl -L https://istio.io/downloadIstio  | ISTIO_VERSION="${INSTALL_ISTIOCTL_VERSION}" sh -
sudo mv -f "istio-${INSTALL_ISTIOCTL_VERSION}/bin/istioctl" /usr/local/bin/istioctl 

istioctl version --short --remote=false || { echo "error: invalid istioctl version"; exit 2; }
