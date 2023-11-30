#!/usr/bin/env bash
set -euo pipefail

nixpkgsFrom="${1:?missing nixpkgsFrom}"

flakeLock="$(echo "${nixpkgsFrom}" | cut -d# -f1)"
input="$(echo "${nixpkgsFrom}" | cut -d# -f2)"

jq -r <"${flakeLock}/flake.lock" '.nodes.root.inputs."'"${input}"'" as $name | .nodes | getpath([$name]).locked | "\(.type):\(.owner)/\(.repo)/\(.rev)"'
