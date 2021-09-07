           

  - when:
      condition: 
        equal: [ << parameters.sonobuoy-version >>, "latest" ]
      steps:
        - run:
            name: install latest version of sonobuoy
            command: |
              export INSTALLED=$(curl -s https://api.github.com/repos/vmware-tanzu/sonobuoy/releases/latest | jq -r '.tag_name')
              curl -SLO "https://github.com/vmware-tanzu/sonobuoy/releases/download/$INSTALLED/sonobuoy_${INSTALLED:1}_linux_amd64.tar.gz"
              sudo tar -xf "sonobuoy_${INSTALLED:1}_linux_amd64.tar.gz"
              sudo mv -f sonobuoy /usr/local/bin/sonobuoy
  - when:
      and:
        - not:
            matches:
              pattern: "^latest$"
              value: << parameters.sonobuoy-version >>
        - not:
            matches:
              pattern: "^executor-version$"
              value: << parameters.sonobuoy-version >>
      steps:
        - run:
            name: install sonobuoy << parameters.sonobuoy-version >>
            command: |
              curl -SLO "https://github.com/vmware-tanzu/sonobuoy/releases/download/v<< parameters.sonobuoy-version >>/sonobuoy_<< parameters.sonobuoy-version >>_linux_amd64.tar.gz"
              sudo tar -xf "sonobuoy_<< parameters.sonobuoy-version >>_linux_amd64.tar.gz"
              sudo mv -f sonobuoy /usr/local/bin/sonobuoy
