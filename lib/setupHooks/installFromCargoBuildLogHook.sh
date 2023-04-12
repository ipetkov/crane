function installFromCargoBuildLog() (
  local dest=${1:-${out}}
  local log=${2:-${cargoBuildLog:?not defined}}

  if ! [ -f "${log}" ]; then
    echo unable to install, cargo build log does not exist at: ${log}
    false
  fi

  echo searching for bins/libs to install from cargo build log at ${log}

  local logs
  logs=$(jq -R 'fromjson?' <"${log}")

  local select_non_test='select(.reason == "compiler-artifact" and .profile.test == false)'
  local select_non_dep='select(contains("/deps/")| not)'
  local select_bins="${select_non_test}"'| .executable | select(.!= null) | '"${select_non_dep}"
  local select_lib_files="${select_non_test}"'
    | select(.target.kind
        | contains(["cdylib"])
        or contains(["dylib"])
        or contains(["staticlib"])
    )
    | .filenames[]
    | select(endswith(".rlib") | not)
    | '"${select_non_dep}"

  function installArtifacts() {
    local loc=${1?:missing}
    mkdir -p "${loc}"

    while IFS= read -r to_install; do
      echo installing ${to_install}
      cp "${to_install}" "${loc}"
    done

    rmdir --ignore-fail-on-non-empty "${loc}"
  }

  command cargo metadata --format-version 1 | jq '.workspace_members[]' | (
    while IFS= read -r ws_member; do
      local select_member="select(.package_id == ${ws_member})"
      echo "${logs}" | jq -r "${select_member} | ${select_lib_files}" | installArtifacts "${dest}/lib"
      echo "${logs}" | jq -r "${select_member} | ${select_bins}" | installArtifacts "${dest}/bin"
    done
  )

  echo searching for bins/libs complete
)
