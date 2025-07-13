#!/usr/bin/env sh

set -eu

scriptDir=$(dirname "$0")
cd "${scriptDir}"

nixpkgsOverride="$(../../ci/ref-from-lock.sh ../../test#nixpkgs)"
craneOverride="--override-input crane ../.. --override-input nixpkgs ${nixpkgsOverride}"
flakeSrc=$(nix flake metadata ${craneOverride} --json 2>/dev/null | jq -r '.path')

# Try building Windows cross package
nix build ${craneOverride} .#
