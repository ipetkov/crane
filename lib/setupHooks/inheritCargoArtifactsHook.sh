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

    if [ -f "${preparedArtifacts}.prev" ]; then
      inheritCargoArtifacts "$(readlink -f "${preparedArtifacts}.prev")" "$cargoTargetDir"
    fi

    echo "decompressing cargo artifacts from ${preparedArtifacts} to ${cargoTargetDir}"

    zstd -d "${preparedArtifacts}" --stdout | \
      tar -x -C "${cargoTargetDir}" --strip-components=1
    rm -f "${cargoTargetDir}/.crane-previous-archive"
    ln -s "${preparedArtifacts}" "${cargoTargetDir}/.crane-previous-archive"

  elif [ -d "${preparedArtifacts}" ]; then
    echo "copying cargo artifacts from ${preparedArtifacts} to ${cargoTargetDir}"

    if [ -n "${doNotLinkInheritedArtifacts}" ]; then
      echo 'will deep copy artifacts (instead of symlinking) as requested'

      # Notes:
      # - --dereference to follow and deeply resolve any symlinks
      # - --no-target-directory to avoid nesting (i.e. `./target/target`)
      # - preserve timestamps to avoid rebuilding
      # - no-preserve ownership (root) so we can make the files writable
      cp -r "${preparedArtifacts}" \
        --dereference \
        --no-target-directory "${cargoTargetDir}" \
        --preserve=timestamps \
        --no-preserve=ownership

      # Keep existing permissions (e.g. exectuable), but also make things writable
      # since the store is read-only and cargo would otherwise choke
      chmod -R u+w "${cargoTargetDir}"

      # NB: cargo also doesn't like it if `.cargo-lock` files remain with a
      # timestamp in the distant past so we need to delete them here
      find "${cargoTargetDir}" -name '.cargo-lock' -delete
    else
      # Dependency .rlib and .rmeta files are content addressed and thus are not written to after
      # being built (since changing `Cargo.lock` would rebuild everything anyway), which makes them
      # good candidates for symlinking (esp. since they can make up 60-70% of the artifact directory
      # on most projects). Thus we ignore them when copying all other artifacts below as we will
      # symlink them afterwards. Note that we scope these checks to the `/deps` subdirectory; the
      # workspace's own .rlib and .rmeta files appear one directory up (and these may require being
      # writable depending on how the actual workspace build is being invoked, so we'll leave them
      # alone).
      #
      # NB: keep the executable bit only if set on the original file
      # but make all files writable as sometimes read-only files will make the build choke
      #
      # NB: cargo also doesn't like it if `.cargo-lock` files remain with a
      # timestamp in the distant past so we avoid copying them here
      rsync \
        --recursive \
        --links \
        --times \
        --chmod=u+w \
        --executability \
        --exclude 'deps/*.rlib' \
        --exclude 'deps/*.rmeta' \
        --exclude '.cargo-lock' \
        "${preparedArtifacts}/" \
        "${cargoTargetDir}/"

      local linkCandidates=$(mktemp linkCandidatesXXXX.txt)
      find "${preparedArtifacts}" \
        '(' -path '*/deps/*.rlib' -or -path '*/deps/*.rmeta' ')' \
        -printf "%P\n" \
        >"${linkCandidates}"

      # Next create any missing directories up front so we can avoid redundant checks later
      cat "${linkCandidates}" \
        | xargs --no-run-if-empty -n1 dirname \
        | sort -u \
        | (cd "${cargoTargetDir}"; xargs --no-run-if-empty mkdir -p)

      # Lastly do the actual symlinking
      cat "${linkCandidates}" \
        | xargs -P ${NIX_BUILD_CORES} -I '##{}##' ln -s "${preparedArtifacts}/##{}##" "${cargoTargetDir}/##{}##"
    fi
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
