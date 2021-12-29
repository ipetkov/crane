installFromCargoArtifactsDir() {
  local dir="$1"
  local libs=".*\.\(so.[0-9.]+\|so\|a\|dylib\)"

  echo "installing artifacts from ${dir}"

  find "${dir}" \
    -maxdepth 1 \
    -regex "${libs}" \
    -print0 | xargs -0 -r cp -t "${out}/lib"

  find "${dir}" \
    -maxdepth 1 \
    -type f \
    -executable \
    ! \( -regex "${libs}" \) \
    -print0 | xargs -0 -r cp -t "${out}/bin"
}

installFromCargoArtifacts() {
  runHook preInstall

  echo "Executing cargoInstall"
  mkdir -p "${out}/bin"
  mkdir -p "${out}/lib"

  for profile in release debug; do
    local dir="${CARGO_TARGET_DIR:-target}/${profile}"
    if [ -d "${dir}" ]; then
      installFromCargoArtifactsDir "${dir}"
      break
    fi
  done

  rmdir --ignore-fail-on-non-empty "${out}/bin"
  rmdir --ignore-fail-on-non-empty "${out}/lib"

  runHook postInstall
}

if [ -z "${dontInstallFromCargoArtifacts-}" ] && [ -z "${installPhase-}" ]; then
  installPhase=installFromCargoArtifacts
fi
