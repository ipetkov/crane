copyCargoTargetToOutput() {
  echo "Executing copyCargoTargetToOutput"
  trap "echo Finished copyCargoTargetToOutput" RETURN

  if [ "1" != "${doCopyTarget}" ]; then
    return
  fi

  # Copy the cargo `target` directory to the `target` output
  mv "${CARGO_TARGET_DIR:-target}" "${target}"
}

postInstallHooks+=(copyCargoTargetToOutput)
