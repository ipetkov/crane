#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.." || exit 1

override_args=()
if [[ -n "${USE_LATEST_RELEASE:-}" ]]; then
  override_args+=(--override-input nixpkgs "$(./ci/ref-from-lock.sh ./test#nixpkgs-latest-release)")
fi

set -x
nix develop .#ci --accept-flake-config --command ./ci/fast-flake-check.sh ./test "${override_args[@]}"
