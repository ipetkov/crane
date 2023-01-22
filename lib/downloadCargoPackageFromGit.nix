{ cargo
, craneUtils
, jq
, lib
, runCommandLocal
}:

{ git
, rev
, ref ? null
, allRefs ? ref == null
}:
let
  maybeRef = lib.optionalAttrs (ref != null) { inherit ref; };
  repo = builtins.fetchGit (maybeRef // {
    inherit allRefs rev;
    url = git;
    submodules = true;
  });

  deps = {
    nativeBuildInputs = [
      cargo
      craneUtils
      jq
    ];
  };
in
runCommandLocal "cargo-git" deps ''
  mkdir -p $out
  existing_crates=()
  while read -r cargoToml; do
    local crate=$(
      cargo metadata --format-version 1 --no-deps --manifest-path "$cargoToml" |
      jq -r '.packages[] | select(.manifest_path == "'"$cargoToml"'") | "\(.name)-\(.version)"'
    )

    if [ -n "$crate" ]; then
      if [[ " ''${existing_crates[*]} " =~ " $crate " ]]; then
        >&2 echo "warning: skipping duplicate package $crate found at $cargoToml"
        continue
      fi

      local dest="$out/$crate"
      cp -r "$(dirname "$cargoToml")" "$dest"
      chmod +w "$dest"
      echo '{"files":{}, "package":null}' > "$dest/.cargo-checksum.json"

      crane-resolve-workspace-inheritance "$cargoToml" > "$dest/Cargo.toml.resolved" &&
        mv "$dest/Cargo.toml"{.resolved,}

      existing_crates+=("$crate")
    fi
  done < <(find ${repo} -name Cargo.toml)
''
