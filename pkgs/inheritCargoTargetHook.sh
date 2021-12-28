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
  preBuildHooks+=(inheritCargoTarget)
else
  echo "inheritCargoTarget not set"
fi
