{ cargo
, jq
, lib
, remarshal
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
      jq
      remarshal
    ];
  };
in
runCommandLocal "cargo-git" deps ''
  mkdir -p $out
  existing_crates=()
  while read -r cargoToml; do
    local crate=$(toml2json <"$cargoToml" | \
      jq -r 'select(.package != null) | .package | "\(.name)-\(.version)"'
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

      existing_crates+=("$crate")
    fi
  done < <(find ${repo} -name Cargo.toml)
''
