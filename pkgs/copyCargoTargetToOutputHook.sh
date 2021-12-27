copyCargoTargetToOutput() {
  echo "Executing copyCargoTargetToOutput"
  trap "echo Finished copyCargoTargetToOutput" RETURN

  local target_dir=${CARGO_TARGET_DIR:-target}

  if [ "1" != "${doCopyTarget}" ]; then
    return
  fi

  if [ "1" = "${doCopyTargetToSeparateOutput}" ]; then
    local dest="${target}"
  else
    mkdir -p "${out}"
    local dest="${out}/target"
  fi

  mv "${target_dir}" "${dest}"
}

postInstallHooks+=(copyCargoTargetToOutput)
