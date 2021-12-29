remapPathPrefix() {
  if [ -z "${cargoVendorDir-}" ]; then
    return
  fi

  local remapArgs="--remap-path-prefix ${cargoVendorDir}=/sources"

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

if [ "1" = "${doRemapSourcePathPrefix-}" ]; then
  postConfigureHooks+=(remapPathPrefix)
fi
