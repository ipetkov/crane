function installFromCargoBuildLog() (
  local dest=${1:-${out}}
  local log=${2:-${cargoBuildLog:?not defined}}

  if ! [ -f "${log}" ]; then
    echo unable to install, cargo build log does not exist at: ${log}
    false
  fi

  echo searching for bins/libs to install from cargo build log at ${log}

  local logs
  logs=$(@jq@ -R 'fromjson?' <"${log}")

  # We automatically ignore any bindeps artifacts as installation candidates.
  # Note that if the same binary is built both as a bindep artifact for something else and as a
  # "regular build", cargo will emit a log entry for each, meaning that we will never accidentally
  # ignore installing a binary that the derivation was intending to build!
  local select_non_deps_artifact='select(contains("/deps/artifact/") | not)'

  # Only install binaries and libraries from the current workspace as a sanity check
  local members="$(command cargo metadata --format-version 1 | @jq@ -c '.workspace_members')"
  local select_non_test_members='select(.reason == "compiler-artifact" and .profile.test == false)
    | select(.package_id as $pid
      | '"${members}"'
      | contains([$pid])
    )'

  local select_bins="${select_non_test_members}| .executable | select(.!= null) | ${select_non_deps_artifact}"
  local select_lib_files="${select_non_test_members}"'
    | select(.target.kind
        | contains(["cdylib"])
        or contains(["dylib"])
        or contains(["staticlib"])
    )
    | .filenames[]
    | select(endswith(".rlib") | not)
    | '"${select_non_deps_artifact}"

  function installArtifacts() {
    local loc=${1?:missing}
    mkdir -p "${loc}"

    while IFS= read -r to_install; do
      echo installing ${to_install}
      cp "${to_install}" "${loc}"
    done

    rmdir --ignore-fail-on-non-empty "${loc}"
  }

  echo "${logs}" | @jq@ -r "${select_lib_files}" | installArtifacts "${dest}/lib"
  echo "${logs}" | @jq@ -r "${select_bins}" | installArtifacts "${dest}/bin"

  echo searching for bins/libs complete
)
