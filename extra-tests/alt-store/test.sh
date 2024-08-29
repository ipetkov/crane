#!/bin/sh
# Regression test for https://github.com/ipetkov/crane/issues/446
set -eu

scriptDir=$(dirname "$0")
cd "${scriptDir}"

nixpkgsOverride="$(../../ci/ref-from-lock.sh ../../test#nixpkgs)"
craneOverride="--override-input crane ../.. --override-input nixpkgs ${nixpkgsOverride}"

case "$(nix --version)" in
  "nix (Nix) 2.21.0" | "nix (Nix) 2.21.1")
    echo 'skipping test: https://github.com/NixOS/nix/issues/10267'
    ;;

  *) nix build .#default ${craneOverride} --store $(pwd)/alt-store
    ;;
esac
