#!/bin/sh

set -eu

scriptDir=$(dirname "$0")
cd "${scriptDir}"

nixpkgsOverride="$(../../ci/ref-from-lock.sh ../../test#nixpkgs)"
craneOverride="--override-input crane ../.. --override-input nixpkgs ${nixpkgsOverride}"

# Try fetching the git verision of cargo
nix build ${craneOverride} .#cargo-git
