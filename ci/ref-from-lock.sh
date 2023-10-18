#!/usr/bin/env bash
set -euo pipefail

flakeLock="${1:?missing flake.lock}"
input="${2:?missing input}"

jq -r <"${flakeLock}/flake.lock" '.nodes.root.inputs."'"${input}"'" as $name | .nodes | getpath([$name]).locked | "\(.type):\(.owner)/\(.repo)/\(.rev)"'
