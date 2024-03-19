#!/bin/sh
# Regression test for https://github.com/ipetkov/crane/issues/446
set -eu

scriptDir=$(dirname "$0")
cd "${scriptDir}"

if [ "nix (Nix) 2.21.0" = "$(nix --version)" ]; then
  echo 'skipping test: https://github.com/NixOS/nix/issues/10267'
else
  nix build .#default --override-input crane ../.. --store $(pwd)/alt-store
fi
