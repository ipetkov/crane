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
}@args:
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
  while read -r cargoToml; do
    local crate=$(toml2json <"$cargoToml" | \
      jq -r 'select(.package != null) | .package | "\(.name)-\(.version)"'
    )

    if [ -n "$crate" ]; then
      local dest="$out/$crate"
      cp -r "$(dirname "$cargoToml")" "$dest"
      chmod +w "$dest"
      echo '{"files":{}, "package":null}' > "$dest/.cargo-checksum.json"
    fi
  done < <(find ${repo} -name Cargo.toml)
''
