configureCargoCommonVars() {
  echo "Executing configureCargoCommonVars"

  # Set a CARGO_HOME if it doesn't exist so cargo does not go
  # looking for a non-existent HOME directory
  export CARGO_HOME=${CARGO_HOME:-${PWD}/.cargo-home}
  mkdir -p ${CARGO_HOME}

  export CARGO_BUILD_JOBS=${CARGO_BUILD_JOBS:-$NIX_BUILD_CORES}
  export RUST_TEST_THREADS=${RUST_TEST_THREADS:-$NIX_BUILD_CORES}

  # Disable incremental builds by default since we don't get a ton of benefit
  # while building with nix. Allow a declared-but-empty variable which will tell
  # cargo to honor the definition used in the build profile
  export CARGO_BUILD_INCREMENTAL=${CARGO_BUILD_INCREMENTAL-false}

  # Used by `cargoWithProfile` to specify a cargo profile to use.
  # Not exported since it is not natively understood by cargo.
  CARGO_PROFILE=${CARGO_PROFILE-release}
}

# NB: run after patching, but before other configure hooks so that we can set
# any default values as early in the process as possible.
postPatchHooks+=(configureCargoCommonVars)
