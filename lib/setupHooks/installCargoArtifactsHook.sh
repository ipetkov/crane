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

compressAndInstallCargoArtifactsDirIncremental() {
  local dir="${1:?destination directory not defined}"
  local cargoTargetDir="${2:?cargoTargetDir not defined}"

  mkdir -p "${dir}"

  local dest="${dir}/target.tar.zst"
  echo "compressing ${cargoTargetDir} to ${dest}"
  (
    export SOURCE_DATE_EPOCH=1
    touch -d @${SOURCE_DATE_EPOCH} "${TMPDIR}/.crane.source-date-epoch"

    find "${cargoTargetDir}" \
      -newer "${TMPDIR}/.crane.source-date-epoch" \
      -print0 \
      | tar \
      --null \
      --no-recursion \
      --sort=name \
      --mtime="@${SOURCE_DATE_EPOCH}" \
      --owner=0 \
      --group=0 \
      --numeric-owner \
      --pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime \
      -c -f - -T - \
      | zstd "-T${NIX_BUILD_CORES:-0}" -o "${dest}"
     if [ -e "${cargoTargetDir}/.crane-previous-archive" ]; then
       cp -a "${cargoTargetDir}/.crane-previous-archive" "${dest}.prev"
     fi
   )
}

dedupAndInstallCargoArtifactsDir() {
  local dest="${1:?destination directory not defined}"
  local cargoTargetDir="${2:?cargoTargetDir not defined}"
  local prevCargoTargetDir="${3:?prevCargoTargetDir not defined}"

  mkdir -p "${dest}"

  if [ -d "${prevCargoTargetDir}" ]; then
    echo "symlinking duplicates in ${cargoTargetDir} to ${prevCargoTargetDir}"

    while read -r fullTargetFile; do
      # Strip the common prefix of the current target directory
      local targetFile="${fullTargetFile#"${cargoTargetDir}"}"
      # Join the path and ensure we don't have a duplicate `/` separator
      local candidateOrigFile="${prevCargoTargetDir}/${targetFile#/}"

      if cmp --silent "${candidateOrigFile}" "${fullTargetFile}"; then
        ln --symbolic --force --logical "${candidateOrigFile}" "${fullTargetFile}"
      fi
    done < <(find "${cargoTargetDir}" -type f)
  fi

  echo installing "${cargoTargetDir}" to "${dest}"
  mv "${cargoTargetDir}" --target-directory="${dest}"
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
      compressAndInstallCargoArtifactsDirIncremental "${dir}" "${cargoTargetDir}"
      ;;

    "use-zstd-no-incr")
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
