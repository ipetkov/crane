# A shell wrapper which logs any `cargo` invocation
cargo() {
  # Run in a subshell to avoid polluting the environment
  (
    set -x
    command cargo "$@"
  )
}

# Injects `--profile $CARGO_PROFILE` into a particular cargo invocation
# if the environment variable is set
cargoWithProfile() {
  local profileArgs
  if [[ "${CARGO_PROFILE}" == "release" ]]; then
    profileArgs="--release"
  else
    profileArgs="${CARGO_PROFILE:+--profile ${CARGO_PROFILE}}"
  fi
  cargo "${@:1:1}" ${profileArgs} "${@:2}"
}
