#!/bin/sh

root="$(dirname "$0")"
nix build -f "${root}/tests" --no-link --keep-going "$@"
