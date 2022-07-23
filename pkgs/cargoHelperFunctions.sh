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
  cargo "${@:1:1}" ${CARGO_PROFILE:+--profile ${CARGO_PROFILE}} "${@:2}"
}
