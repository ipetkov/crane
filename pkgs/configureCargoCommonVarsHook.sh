configureCargoCommonVars() {
  echo "Executing configureCargoCommonVars"

  export CARGO_BUILD_JOBS=${CARGO_BUILD_JOBS:-$NIX_BUILD_CORES}
  export RUST_TEST_THREADS=${RUST_TEST_THREADS:-$NIX_BUILD_CORES}

  # Disable incremental builds by default since we don't get a ton of benefit
  # while building with nix. Allow a declared-but-empty variable which will tell
  # cargo to honor the definition used in the build profile
  export CARGO_BUILD_INCREMENTAL=${CARGO_BUILD_INCREMENTAL-false}

  echo "Finished configureCargoCommonVars"
}

preConfigureHooks+=(configureCargoCommonVars)
