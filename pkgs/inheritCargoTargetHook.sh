inheritCargoTarget() {
  echo "Executing inheritCargoTarget"

  local cargoTarget="${CARGO_TARGET_DIR:-target}"
  mkdir -p "${cargoTarget}"

  if [ -f "${inheritCargoTarget}/target.tar.zst" ]; then
    @zstd@ -d "${inheritCargoTarget}/target.tar.zst" --stdout | \
      tar -x -C "${cargoTarget}" --strip-components=1
  elif [ -d "${inheritCargoTarget}/target" ]; then
    @rsync@ \
      --recursive \
      --links \
      --executability \
      --chmod=+w \
      --no-perms \
      --no-owner \
      --no-group \
      "${inheritCargoTarget}/target" "${cargoTarget}"
  else
    echo "${inheritCargoTarget} looks invalid, are you sure it is pointing to a ".target" output?"
    false
  fi
}

if [ -n "${inheritCargoTarget-}" ]; then
  # NB: inherit cargo artifacts after patching is done, that way target directory
  # is fresher than the source and avoid invalidating the cache
  # Doing this as early as possible also gives us the advantage that any other
  # preBuild hooks (e.g. clippy) can also take advantage of the cache
  postPatchHooks+=(inheritCargoTarget)
else
  echo "inheritCargoTarget not set, will not reuse any cargo artifacts"
fi
