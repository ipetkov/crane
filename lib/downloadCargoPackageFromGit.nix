{ lib
, cargo
, craneUtils
, jq
, pkgsBuildBuild
}:

let
  inherit (pkgsBuildBuild)
    fetchgit
    stdenv;
in
{ git
, rev
, ref ? null
, hash ? null
, allRefs ? ref == null
}:
let
  maybeRef = lib.optionalAttrs (ref != null) { inherit ref; };
  repo =
    if hash == null then
      builtins.fetchGit
        (maybeRef // {
          inherit allRefs rev;
          url = git;
          submodules = true;
        })
    else
      fetchgit {
        inherit rev hash;
        url = git;
        fetchSubmodules = true;
        fetchLFS = true;
      };
in
stdenv.mkDerivation {
  name = "cargo-git";
  src = repo;

  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  depsBuildBuild = [
    cargo
    craneUtils
    jq
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    declare -A existing_crates
    find "$(pwd)" -name Cargo.toml | while read -r cargoToml; do
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
    done

    runHook postInstall
  '';
}
