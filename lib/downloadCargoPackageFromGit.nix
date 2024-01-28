{ lib
, pkgsBuildBuild
}:

let
  inherit (pkgsBuildBuild)
    cargo
    fetchgit
    jq
    runCommand;

  craneUtils = pkgsBuildBuild.callPackage ../pkgs/crane-utils { };
in
{ git
, rev
, ref ? null
, sha256 ? null
, allRefs ? ref == null
}:
let
  maybeRef = lib.optionalAttrs (ref != null) { inherit ref; };
  repo =
    if sha256 == null then
      builtins.fetchGit
        (maybeRef // {
          inherit allRefs rev;
          url = git;
          submodules = true;
        })
    else
      fetchgit {
        inherit rev sha256;
        url = git;
        fetchSubmodules = true;
      };

  deps = {
    nativeBuildInputs = [
      cargo
      craneUtils
      jq
    ];
  };
in
runCommand "cargo-git" deps ''
  mkdir -p $out
  declare -A existing_crates
  while read -r cargoToml; do
    local crate=$(
      cargo metadata --format-version 1 --no-deps --manifest-path "$cargoToml" |
      jq -r '.packages[] | select(.manifest_path == "'"$cargoToml"'") | "\(.name)-\(.version)"'
    )

    if [ -n "$crate" ]; then
      if [[ -n "''${existing_crates["$crate"]}" ]]; then
        >&2 echo "warning: skipping duplicate package $crate found at $cargoToml"
        continue
      fi

      local dest="$out/$crate"
      cp -rL "$(dirname "$cargoToml")" "$dest"
      chmod +w "$dest"
      echo '{"files":{}, "package":null}' > "$dest/.cargo-checksum.json"

      crane-resolve-workspace-inheritance "$cargoToml" > "$dest/Cargo.toml.resolved" &&
        mv "$dest/Cargo.toml"{.resolved,}

      existing_crates["$crate"]='1'
    fi
  done < <(find ${repo} -name Cargo.toml)
''
