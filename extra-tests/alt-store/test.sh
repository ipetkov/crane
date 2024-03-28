#!/bin/sh
# Regression test for https://github.com/ipetkov/crane/issues/446
set -eu

scriptDir=$(dirname "$0")
cd "${scriptDir}"

case "$(nix --version)" in
  "nix (Nix) 2.21.0" | "nix (Nix) 2.21.1")
    echo 'skipping test: https://github.com/NixOS/nix/issues/10267'
    ;;

  *) nix build .#default --override-input crane ../.. --store $(pwd)/alt-store
    ;;
esac
