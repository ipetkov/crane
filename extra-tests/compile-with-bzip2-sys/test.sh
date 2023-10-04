#!/bin/sh

set -eu

scriptDir=$(dirname "$0")
cd "${scriptDir}"

craneOverride="--override-input crane ../.."

# Try building. If it works, we are good.
nix build ${craneOverride}
