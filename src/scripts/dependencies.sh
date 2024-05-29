#!/usr/bin/env bash
InstallDependencies() {
  if [ "$USE_SUDO" == "true" ]; then export SUDO=""; else # Check if we're root
    export SUDO="sudo";
    echo "$SUDO"
  fi
  if cat /etc/issue | grep Alpine > /dev/null 2>&1; then
    command -v curl >/dev/null 2>&1 || { "$SUDO" apk add --no-cache curl; }
    command -v tar >/dev/null 2>&1 || { "$SUDO" apk add --no-cache tar; }
  elif cat /etc/issue | grep Debian > /dev/null 2>&1 || cat /etc/issue | grep Ubuntu > /dev/null 2>&1; then
    command -v curl >/dev/null 2>&1 || { "$SUDO" apt -qq install -y curl; }
    command -v tar >/dev/null 2>&1 || { "$SUDO" apt -qq install -y tar; }
  fi
}
