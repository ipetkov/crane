#!/bin/sh

set -eu

scriptDir=$(dirname "$0")
cd "${scriptDir}"

craneOverride="--override-input crane ../.."
flakeSrc=$(nix flake metadata ${craneOverride} --json 2>/dev/null | jq -r '.path')

# Try fetching the git verision of cargo
nix build ${craneOverride} .#cargo-git -L
