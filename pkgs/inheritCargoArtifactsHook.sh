inheritCargoArtifacts() {
  # Allow for calling with customized parameters
  # or fall back to defaults if none are provided
  local preparedArtifacts="${1:-${cargoArtifacts:?not defined}}"
  local cargoTargetDir="${2:-${CARGO_TARGET_DIR:-target}}"

  if [ -d "${preparedArtifacts}" ]; then
    local preparedArtifacts="${preparedArtifacts}/target.tar.zst"
  fi

  if [ -f "${preparedArtifacts}" ]; then
    mkdir -p "${cargoTargetDir}"
    echo "copying cargo artifacts from ${preparedArtifacts} to ${cargoTargetDir}"
  
    @zstd@ -d "${preparedArtifacts}" --stdout | \
      tar -x -C "${cargoTargetDir}" --strip-components=1
  else
    echo unable to copy cargo artifacts, \"${preparedArtifacts}\" looks invalid
    false
  fi
}

if [ -n "${cargoArtifacts-}" ]; then
  # NB: inherit cargo artifacts after patching is done, that way target directory
  # is fresher than the source and avoid invalidating the cache
  # Doing this as early as possible also gives us the advantage that any other
  # preBuild hooks (e.g. clippy) can also take advantage of the cache
  postPatchHooks+=(inheritCargoArtifacts)
else
  echo "cargoArtifacts not set, will not reuse any cargo artifacts"
fi
