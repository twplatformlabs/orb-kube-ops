



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
