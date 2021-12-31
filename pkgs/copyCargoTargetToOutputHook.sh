copyCargoTargetToOutput() {
  echo "Executing copyCargoTargetToOutput"

  export SOURCE_DATE_EPOCH=1
  mkdir -p "${target}"

  # See: https://reproducible-builds.org/docs/archives/
  tar --sort=name \
    --mtime="@${SOURCE_DATE_EPOCH}" \
    --owner=0 --group=0 --numeric-owner \
    --pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime \
    -c "${CARGO_TARGET_DIR:-target}" | @zstd@ -o "${target}/target.tar.zst"
}

if [ "1" = "${doCopyTargetToOutput-}" ]; then
  postInstallHooks+=(copyCargoTargetToOutput)
fi
