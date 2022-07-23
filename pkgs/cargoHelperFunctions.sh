# A shell wrapper which logs any `cargo` invocation
cargo() {
  # Run in a subshell to avoid polluting the environment
  (
    set -x
    command cargo "$@"
  )
}
