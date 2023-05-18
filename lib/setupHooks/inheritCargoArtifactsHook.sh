inheritCargoArtifacts() {
  # Allow for calling with customized parameters
  # or fall back to defaults if none are provided
  local preparedArtifacts="${1:-${cargoArtifacts:?not defined}}"
  local cargoTargetDir="${2:-${CARGO_TARGET_DIR:-target}}"

  if [ -d "${preparedArtifacts}" ]; then
    local candidateTarZst="${preparedArtifacts}/target.tar.zst"
    local candidateTargetDir="${preparedArtifacts}/target"

    if [ -f "${candidateTarZst}" ]; then
      local preparedArtifacts="${candidateTarZst}"
    elif [ -d "${candidateTargetDir}" ]; then
      local preparedArtifacts="${candidateTargetDir}"
    fi
  fi

  mkdir -p "${cargoTargetDir}"
  if [ -f "${preparedArtifacts}" ]; then
    echo "decompressing cargo artifacts from ${preparedArtifacts} to ${cargoTargetDir}"

    zstd -d "${preparedArtifacts}" --stdout | \
      tar -x -C "${cargoTargetDir}" --strip-components=1
  elif [ -d "${preparedArtifacts}" ]; then
    echo "copying cargo artifacts from ${preparedArtifacts} to ${cargoTargetDir}"

    # copy target dir but ignore content-addressed build artifacts
    rsync -r --chmod=Du=rwx --exclude "*/build/*" --exclude "*/deps/*" --exclude "*/*/build/*" --exclude "*/*/deps/*" "${preparedArtifacts}/" "${cargoTargetDir}/"

    # symlink all remaining content-addressed artifacts
    pushd "${cargoTargetDir}"
      for d in $(ls -d */{deps,build} */*/{deps,build}); do
          ls "${preparedArtifacts}/${d}" | xargs -P 100 -I '##{}##' ln -fs "${preparedArtifacts}/${d}/##{}##" "${d}/##{}##"
      done
    popd

    # Keep existing permissions (e.g. exectuable), but also make things writable
    # since the store is read-only and cargo would otherwise choke
    chmod -R u+w "${cargoTargetDir}"

    # NB: cargo also doesn't like it if `.cargo-lock` files remain with a
    # timestamp in the distant past so we need to delete them here
    find "${cargoTargetDir}" -name '.cargo-lock' -delete
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
