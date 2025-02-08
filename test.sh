#!/bin/sh
set -euo pipefail

gitRoot="$(git rev-parse --show-toplevel)"
cd "${gitRoot}"

function flakeCheck() {
  if which nom >/dev/null 2>&1; then
    nix flake check --log-format internal-json -v -L "$@" |& nom --json
  else
    nix flake check -L "$@"
  fi
}

flakeCheck
flakeCheck ./test#
flakeCheck ./test# --override-input nixpkgs "$("${gitRoot}/ci/ref-from-lock.sh" "${gitRoot}/test#nixpkgs-latest-release")"

for f in $(find ./examples -maxdepth 1 -mindepth 1 -type d | sort -u); do
  echo "validating ${f}"
  "${gitRoot}/ci/check-example.sh" "${f}" "${gitRoot}/test#nixpkgs"
done
