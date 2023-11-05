compressAndInstallCargoArtifactsDir() {
  local dir="${1:?destination directory not defined}"
  local cargoTargetDir="${2:?cargoTargetDir not defined}"
  local prevArtifacts="${3}"

  mkdir -p "${dir}"

  local dest="${dir}/target.tar.zst"
  (
    export SOURCE_DATE_EPOCH=1

    dynTar() {
      if [ -n "${doCompressAndInstallFullArchive}" ]; then
        >&2 echo "compressing and installing full archive of ${cargoTargetDir} to ${dest} as requested"
        tar "$@" "${cargoTargetDir}"
      elif [ "$(uname -s)" == "Darwin" ]; then
        # https://github.com/rust-lang/rust/issues/115982
        >&2 echo "incremental zstd compression not currently supported on Darwin: https://github.com/rust-lang/rust/issues/115982"
        >&2 echo "doing a full archive install of ${cargoTargetDir} to ${dest}"
        tar "$@" "${cargoTargetDir}"
      elif [ -z "${prevArtifacts}" ]; then
        >&2 echo "no previous artifacts found, compressing and installing full archive of ${cargoTargetDir} to ${dest}"
        tar "$@" "${cargoTargetDir}"
      else
        >&2 echo "linking previous artifacts ${prevArtifacts} to ${dest}"
        ln -s "${prevArtifacts}" "${dest}.prev"
        touch -d @${SOURCE_DATE_EPOCH} "${TMPDIR}/.crane.source-date-epoch"
        tar \
          --null \
          --no-recursion \
          -T <(find "${cargoTargetDir}" -newer "${TMPDIR}/.crane.source-date-epoch" -print0) \
          "$@"
      fi
    }

    dynTar \
      --sort=name \
      --mtime="@${SOURCE_DATE_EPOCH}" \
      --owner=0 \
      --group=0 \
      --mode=u+w \
      --numeric-owner \
      --pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime \
      -c | zstd "-T${NIX_BUILD_CORES:-0}" -o "${dest}" ${zstdCompressionExtraArgs:-}
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
  local mode="${3:-${installCargoArtifactsMode:-use-zstd}}"
  local prevCargoArtifacts="${4:-${cargoArtifacts:""}}"

  mkdir -p "${dir}"

  case "${mode}" in
    "use-zstd")
      local prevCandidateTarZst="${prevCargoArtifacts}/target.tar.zst"
      if [ -f "${prevCandidateTarZst}" ]; then
        local prevCargoArtifacts="${prevCandidateTarZst}"
      fi
      compressAndInstallCargoArtifactsDir "${dir}" "${cargoTargetDir}" "${prevCargoArtifacts}"
      ;;

    "use-symlink")
      # Placeholder if previous artifacts aren't present
      local prevCargoTargetDir="/dev/null"
      if [ -n "${prevCargoArtifacts}" ] && [ -d "${prevCargoArtifacts}/target" ]; then
        local prevCargoTargetDir="${prevCargoArtifacts}/target"
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
