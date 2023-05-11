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

    # copy target dir but ignore crate build artifacts
    rsync -r --chmod=Du=rwx,Dg=rx,Do=rx --exclude "release/build" --exclude "release/deps" --exclude "*/release/build" --exclude "*/release/deps" "${preparedArtifacts}/" "${cargoTargetDir}/"

    link_build_artifacts() {
      local artifacts="$1"
      local target="$2"

      if [ -d "${artifacts}/release/deps" ]; then
        mkdir -p "${target}/release/deps"
        for dep in $(ls "${artifacts}/release/deps"); do
          ln -fs "${artifacts}/release/deps/$dep" "${target}/release/deps/$dep"
        done
      fi

      if [ -d "${artifacts}/release/build" ]; then
        mkdir -p "${target}/release/build"
        for build in $(ls "${artifacts}/release/build"); do
          ln -fs "${artifacts}/release/build/$build" "${target}/release/build/$build"
        done
      fi
    }

    # symlink crate build artifacts
    link_build_artifacts "${preparedArtifacts}" "${cargoTargetDir}"

    # for each build target as well
    # all other directories are ignored in `link_build_artifacts`
    for target in $(ls "${preparedArtifacts}"); do
      link_build_artifacts "${preparedArtifacts}/$target" "${cargoTargetDir}/$target"
    done

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
