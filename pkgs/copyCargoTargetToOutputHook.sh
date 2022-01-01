prepareCargoTargetDirAndCopyToDir() {
  # Allow for calling with customized parameters
  # or fall back to defaults if none are provided
  local dir="${1:-${out}}"
  local cargoTargetDir="${2:-${CARGO_TARGET_DIR:-target}}"
  local dest="${dir}/target.tar.zst"

  echo "copying ${cargoTargetDir} to ${dest}"

  export SOURCE_DATE_EPOCH=1
  mkdir -p "${dir}"

  # See: https://reproducible-builds.org/docs/archives/
  tar --sort=name \
    --mtime="@${SOURCE_DATE_EPOCH}" \
    --owner=0 \
    --group=0 \
    --numeric-owner \
    --pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime \
    -c "${cargoTargetDir}" | @zstd@ -o "${dest}"
}

if [ "1" = "${doCopyTargetToOutput-}" ]; then
  postInstallHooks+=(prepareCargoTargetDirAndCopyToDir)
fi
