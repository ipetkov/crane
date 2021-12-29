inheritCargoArtifacts() {
  echo "Executing inheritCargoArtifacts"

  local cargoTarget="${CARGO_TARGET_DIR:-target}"
  mkdir -p "${cargoTarget}"

  if [ -f "${cargoArtifacts}/target.tar.zst" ]; then
    @zstd@ -d "${cargoArtifacts}/target.tar.zst" --stdout | \
      tar -x -C "${cargoTarget}" --strip-components=1
  elif [ -d "${cargoArtifacts}/target" ]; then
    @rsync@ \
      --recursive \
      --links \
      --executability \
      --chmod=+w \
      --no-perms \
      --no-owner \
      --no-group \
      "${cargoArtifacts}/target" "${cargoTarget}"
  else
    echo "${cargoArtifacts} looks invalid, are you sure it is pointing to a ".target" output?"
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
