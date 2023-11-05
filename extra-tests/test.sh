#!/bin/sh

set -eu

anyFailed=0

runTest() {
  local testPath="$1"

  if ${testPath}; then
    echo "pass: ${testPath}"
  else
    echo "fail: ${testPath}"
    anyFailed=1
  fi
}

scriptPath=$(dirname "$0")
cd "${scriptPath}"

runTest ./alt-store/test.sh
runTest ./dummy-does-not-depend-on-flake-source-via-path/test.sh
runTest ./dummy-does-not-depend-on-flake-source-via-self/test.sh
runTest ./fetch-cargo-git/test.sh

exit ${anyFailed}
