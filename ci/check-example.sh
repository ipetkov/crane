#!/usr/bin/env bash
set -euo pipefail

gitRoot="$(git rev-parse --show-toplevel)"

example="${1:?missing example}"
nixpkgsFrom="${2:?missing nixpkgsFrom}"
shift 2

chosenNixpkgs="$("${gitRoot}/ci/ref-from-lock.sh" "${nixpkgsFrom}")"

commonArgs=(
  "${example}"
  --override-input crane "${gitRoot}"
  --override-input nixpkgs "${chosenNixpkgs}"
  "$@"
)

echo "--- checking ${example}"

# nix-eval-jobs doesn't (yet) support --reference-lock-file: https://github.com/nix-community/nix-eval-jobs/pull/210
# Nix older than 2.15 also doesn't support it
cp {"${gitRoot}/test","${example}"}/flake.lock
trap "rm -f ${example}/flake.lock" EXIT

"${gitRoot}/ci/fast-flake-check.sh" "${commonArgs[@]}"

# NB: evaluate the rest flake here, but don't build anything
nix flake check \
  --no-build \
  --no-write-lock-file \
  --accept-flake-config \
  --print-build-logs \
  "${commonArgs[@]}"
