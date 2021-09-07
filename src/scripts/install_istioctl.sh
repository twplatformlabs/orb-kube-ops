  - when:
      condition: 
        equal: [ << parameters.istioctl-version >>, "latest" ]
      steps:
        - run:
            name: install latest version of istioctl
            command: |
              curl -L https://istio.io/downloadIstio  | sh -
              export INSTALLED=$(istio-*/bin/istioctl version --remote=false)
              sudo mv -f "istio-$INSTALLED/bin/istioctl" /usr/local/bin/istioctl
  - when:
      and:
        - not:
            matches:
              pattern: "^latest$"
              value: << parameters.istioctl-version >>
        - not:
            matches:
              pattern: "^executor-version$"
              value: << parameters.istioctl-version >>
      steps:
        - run:
            name: install istioctl << parameters.istioctl-version >>
            command: |
              curl -L https://istio.io/downloadIstio  | ISTIO_VERSION="<< parameters.istioctl-version >>" sh -
              sudo mv -f "istio-<< parameters.istioctl-version >>/bin/istioctl" /usr/local/bin/istioctl 
