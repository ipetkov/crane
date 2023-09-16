compressAndInstallCargoArtifactsDir() {
  local dir="${1:?destination directory not defined}"
  local cargoTargetDir="${2:?cargoTargetDir not defined}"

  mkdir -p "${dir}"

  local dest="${dir}/target.tar.zst"
  echo "compressing ${cargoTargetDir} to ${dest}"
  (
    export SOURCE_DATE_EPOCH=1
    tar --sort=name \
      --mtime="@${SOURCE_DATE_EPOCH}" \
      --owner=0 \
      --group=0 \
      --numeric-owner \
      --pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime \
      -c "${cargoTargetDir}" | zstd "-T${NIX_BUILD_CORES:-0}" -o "${dest}"
  )
}

dedupAndInstallCargoArtifactsDir() {
  local dest="${1:?destination directory not defined}"
  local cargoTargetDir="${2:?cargoTargetDir not defined}"
  local prevCargoTargetDir="${3:?prevCargoTargetDir not defined}"

  mkdir -p "${dest}"

  echo installing "${cargoTargetDir}" to "${dest}"
  mv "${cargoTargetDir}" --target-directory="${dest}"

  local symlinksDir="$(mktemp -d)"
  cp -Rs "${dir}/target" "${symlinksDir}"
  if test -n "$(shopt -s nullglob; echo $symlinksDir/target/*/deps)"; then
    pushd "$symlinksDir"
    tar -cf "${dir}/symlinks.tar" target/*/deps
    popd
  fi
}

prepareAndInstallCargoArtifactsDir() {
  # Allow for calling with customized parameters
  # or fall back to defaults if none are provided
  local dir="${1:-${out}}"
  local cargoTargetDir="${2:-${CARGO_TARGET_DIR:-target}}"
  local mode="${3:-${installCargoArtifactsMode:-use-symlink}}"

  mkdir -p "${dir}"

  case "${mode}" in
    "use-zstd")
      compressAndInstallCargoArtifactsDir "${dir}" "${cargoTargetDir}"
      ;;

    "use-symlink")
      # Placeholder if previous artifacts aren't present
      local prevCargoTargetDir="/dev/null"

      if [ -n "${cargoArtifacts}" ] && [ -d "${cargoArtifacts}/target" ]; then
        local prevCargoTargetDir="${cargoArtifacts}/target"
      fi

      dedupAndInstallCargoArtifactsDir "${dir}" "${cargoTargetDir}" "${prevCargoTargetDir}"
      ;;

    *)
      echo "unknown mode: \"${mode}\""
      false
      ;;
  esac
}

if [ "1" = "${doInstallCargoArtifacts-}" ]; then
  postInstallHooks+=(prepareAndInstallCargoArtifactsDir)
fi
