remapPathPrefix() {
  # We unfortunately cannot get away with *just* stripping a `/nix/store` prefix
  # since nix will still find references to the `<sha>-dirname` floating around
  # and decide that the binaries must depend on the source files themselves.
  # To get around this we actually have to strip the entire prefix of the vendored
  # directory (or provided input).
  local prefixToRemap=${1:?prefixToRemap not specified}
  local remapArgs="--remap-path-prefix ${prefixToRemap}=/sources"

  if [ -n "${RUSTFLAGS}" ]; then
    export RUSTFLAGS="${RUSTFLAGS} ${remapArgs}"
    echo "setting RUSTFLAGS to \"${RUSTFLAGS}\""
  else
    if [ -n "${CARGO_BUILD_RUSTFLAGS}" ]; then
      export CARGO_BUILD_RUSTFLAGS="${CARGO_BUILD_RUSTFLAGS} ${remapArgs}"
    else
      export CARGO_BUILD_RUSTFLAGS="${remapArgs}"
    fi
    echo "setting CARGO_BUILD_RUSTFLAGS to \"${CARGO_BUILD_RUSTFLAGS}\""
  fi
}

remapPathPrefixToVendoredDir() {
  if [ -n "${cargoVendorDir-}" ]; then
    remapPathPrefix "${cargoVendorDir}"
  fi
}

if [ "1" = "${doRemapSourcePathPrefix-}" ]; then
  postConfigureHooks+=(remapPathPrefixToVendoredDir)
fi
