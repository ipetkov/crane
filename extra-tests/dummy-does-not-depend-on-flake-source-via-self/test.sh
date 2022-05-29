#!/bin/sh

set -eu

scriptDir=$(dirname "$0")
cd "${scriptDir}"

craneOverride="--override-input crane ../.."
flakeSrc=$(nix flake metadata ${craneOverride} --json 2>/dev/null | jq -r '.path')

# Get information about the default derivation
# Then pull out any input sources
drvSrcs=$(nix show-derivation ${craneOverride} '.#dummy' 2>/dev/null |
  jq -r 'to_entries[].value.inputSrcs[]')

# And lastly make sure we DO NOT find the flake root source listed
# or else the dummy derivation will depend on _too much_ (and get
# invalidated with irrelevant changes)
if echo "${drvSrcs}" | grep -q -F "${flakeSrc}"; then
  echo "error: dummy derivation depends on flake source"
  exit 1
fi
