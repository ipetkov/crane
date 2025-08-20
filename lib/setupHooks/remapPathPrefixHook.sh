configureRustcRemapPathPrefix() {
  local remapTo="${1:-${srcForRemapPathPrefix:-${src:?not defined}}}"
  local remapFrom="${2:-$(pwd)}"

  # NB: in cargo's hierarchy of where it will source values for RUSTFLAGS, this env var
  # is the last in terms or priority. Therefore we don't need to worry about accidentally
  # clobbering any user configured values (e.g. like in `[target.<triple>.rustflags]`
  # https://doc.rust-lang.org/cargo/reference/config.html#buildrustflags
  echo "configuring CARGO_BUILD_RUSTFLAGS to remap paths from \"${remapFrom}\" to \"${remapTo}\""
  set -x
  CARGO_BUILD_RUSTFLAGS="${CARGO_BUILD_RUSTFLAGS:-} --remap-path-prefix=${remapFrom}=${remapTo}"
  set +x
  export CARGO_BUILD_RUSTFLAGS
}

# NB: using `-` as the outer expansion here, not `:-`: if `doRemapPathPrefix`
# is set but null, skip the fallback to `dontStrip`
if [ -n "${doRemapPathPrefix-${dontStrip:-}}" ]; then
  # NB: run after all other configure hooks have finished, so right before builds start
  preBuildHooks+=(configureRustcRemapPathPrefix)
else
  echo "doRemapPathPrefix not set, will not configure any source remapping"
fi
