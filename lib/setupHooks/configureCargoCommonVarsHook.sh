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

  # Apply __CRANE_EXPORT_XYZ variables, setting XYZ accordingly unless said
  # variable has already been set elsewhere.
  local craneVar
  for craneVar in ${!__CRANE_EXPORT_*}; do
    local cargoVar="${craneVar#__CRANE_EXPORT_}"
    if [ -z "${!cargoVar}" ]; then
      local value="${!craneVar}"
      # Be loud about this in case the user is unaware that we set this
      # variable, and as a result we break their build setup in some way
      echo "NOTICE: setting $cargoVar='$value' for cross-compilation purposes"
      echo " - if this is unwanted, you can set $cargoVar yourself"
      echo ' - alternatively, you can disable the built-in cross compilation support'
      echo '   by setting `noCrossToolchainEnv = false` in the derivation'
      export "${cargoVar}"="${value}"
    fi
  done
}

# NB: run after patching, but before other configure hooks so that we can set
# any default values as early in the process as possible.
postPatchHooks+=(configureCargoCommonVars)
