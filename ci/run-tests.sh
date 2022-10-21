#!/usr/bin/env bash
set -eu

NIXPKGS_STABLE="github:NixOS/nixpkgs/release-22.05"

main() {
  cd $(dirname "$0")/..

  # Run all tests by default
  runStable="1"
  runLocked="1"

  while [ $# -gt 0 ]; do
    case "$1" in
      "--locked")
        runLocked="1"
        runStable=""
        ;;
      "--stable")
        runLocked=""
        runStable="1"
        ;;
      *)
        echo "unrecognized option $1"
        exit 1
        ;;
    esac
  done

  if [ -n "${runLocked}" ]; then
    runtests
  fi

  if [ -n "${runStable}" ]; then
    runtests "--override-input nixpkgs ${NIXPKGS_STABLE}"
  fi
}

runtests() {
  overrideArgs=""

  if [ $# -gt 0 ]; then
    overrideArgs="$1"
  fi

  echo running flake checks
  nix flake check --keep-going --print-build-logs ${overrideArgs}

  echo running extra tests
  nix develop ${overrideArgs} --command ./extra-tests/test.sh

  for f in $(find examples -maxdepth 1 -mindepth 1 -type d); do
    pushd "${f}"
    echo "validating ${f}"
    nix flake check --print-build-logs --keep-going --override-input crane ../.. $overrideArgs
    nix run --override-input crane ../.. ${overrideArgs}
    popd
  done
}

main
