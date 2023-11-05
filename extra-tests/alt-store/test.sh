#!/bin/sh
# Regression test for https://github.com/ipetkov/crane/issues/446
set -eu

scriptDir=$(dirname "$0")
cd "${scriptDir}"

nix build .#default --override-input crane ../.. --store $(pwd)/alt-store
