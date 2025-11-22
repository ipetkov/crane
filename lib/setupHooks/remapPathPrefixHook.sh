configureRustcRemapPathPrefix() {
  local remapTo="${1:-${src:?not defined}}"
  local remapFrom="${2:-$(pwd)}"

  echo "configuring CARGO_BUILD_RUSTFLAGS to remap paths from \"${remapFrom}\" to \"${remapTo}\""

  # NB: we don't want to directly remap to $src, since this will cause excess
  # rebuilds stemming from CARGO_BUILD_RUSTFLAGS-related build fingerprint
  # changes, as buildDepsOnly will be invoked with $src pointing to a `dummySrc`
  # output`. Instead, we first "neuter" the path to a common intermediate by
  # stripping the hash part of the path, which we fix up later.
  local remapToHash=$(echo "$remapTo" | grep --only-matching '@storeDir@/[a-z0-9]\{32\}')
  if [ "${3:-neuter}" == "neuter" ] && [ -n "$remapToHash" ]; then
    postBuildHooks+=("fixupNeuteredRustcRemapPathPrefix \"${remapTo}\"")

    remapTo=$(echo "$remapTo" | sed "s|${remapToHash}|@storeDir@/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee|g")
    echo " - neutering as \"${remapTo}\" for source path remapping"

    if [ -z "${noCompressDebugSectionsSet}" ]; then
      # NB: future proofing in case this option ever becomes the default
      CARGO_BUILD_RUSTFLAGS="${CARGO_BUILD_RUSTFLAGS:-} -C link-arg=-Wl,--compress-debug-sections=none"
      noCompressDebugSectionsSet=1
    fi
  fi

  # NB: in cargo's hierarchy of where it will source values for RUSTFLAGS, this env var
  # is the last in terms or priority. Therefore we don't need to worry about accidentally
  # clobbering any user configured values (e.g. like in `[target.<triple>.rustflags]`
  # https://doc.rust-lang.org/cargo/reference/config.html#buildrustflags
  set -x
  CARGO_BUILD_RUSTFLAGS="${CARGO_BUILD_RUSTFLAGS:-} --remap-path-prefix=${remapFrom}=${remapTo}"
  set +x
  export CARGO_BUILD_RUSTFLAGS
}

fixupNeuteredRustcRemapPathPrefix() {
  local remapTo="${1:?not defined}"
  local buildLocation="${2:-$(pwd)}"

  local remapToHash=$(echo "$remapTo" | grep --only-matching '@storeDir@/[a-z0-9]\{32\}')

  echo "fixing up neutered remapped \"${remapTo}\" source path references"
  find "${buildLocation}" -type f -print0 | xargs -0 --no-run-if-empty sed -i'' "s|@storeDir@/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee|${remapToHash}|g"
}

# NB: using `-` as the outer expansion here, not `:-`: if `doRemapPathPrefix`
# is set but null, skip the fallback to `dontStrip`
if [ -n "${doRemapPathPrefix-${dontStrip:-}}" ]; then
  # NB: run after all other configure hooks have finished, so right before builds start
  preBuildHooks+=(configureRustcRemapPathPrefix)
else
  echo "doRemapPathPrefix not set, will not configure any source remapping"
fi
