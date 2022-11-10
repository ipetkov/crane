#!/bin/sh

set -eu

scriptDir=$(dirname "$0")
cd "${scriptDir}"

craneOverride="--override-input crane ../.."

# Try fetching the git verision of cargo
nix build ${craneOverride} .#cargo-git
