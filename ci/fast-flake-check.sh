#!/usr/bin/env bash
curSystem=$(nix eval --raw --impure --expr builtins.currentSystem)

nixEvalJobsArgs=()
while [[ $# -gt 0 ]]; do
  arg="$1"
  shift 1

  if [[ "${arg}" == '--' ]]; then
    break
  fi

  nixEvalJobsArgs+=("$arg")
done

nix-eval-jobs \
  --gc-roots-dir gcroot \
  --check-cache-status \
  --flake ".#checks.${curSystem}" \
  "${nixEvalJobsArgs[@]}" \
  | jq -r 'select(.isCached | not).drvPath as $drvPath | "\($drvPath)^*"' \
  | xargs --no-run-if-empty nix build --no-link --print-build-logs "$@"
