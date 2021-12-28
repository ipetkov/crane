copyCargoTargetToOutput() {
  echo "Executing copyCargoTargetToOutput"

  if [ "1" != "${doCopyTarget-}" ]; then
    return
  fi

  export SOURCE_DATE_EPOCH=1
  mkdir -p "${target}"

  if [ "1" != "${doCompressTarget-}" ]; then
    # Copy the cargo `target` directory to the `target` output
    mv "${CARGO_TARGET_DIR:-target}" "${target}/target"
    return
  fi

  # See: https://reproducible-builds.org/docs/archives/
  tar --sort=name \
    --mtime="@${SOURCE_DATE_EPOCH}" \
    --owner=0 --group=0 --numeric-owner \
    --pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime \
    -c target | @zstd@ -o "${target}/target.tar.zst"
}

postInstallHooks+=(copyCargoTargetToOutput)
