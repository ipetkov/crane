{
  lib,
  cargo,
  craneUtils,
  jq,
  pkgsBuildBuild,
  remarshal,
  ripgrep,
}:

let
  inherit (pkgsBuildBuild)
    fetchgit
    stdenv
    ;

  namePrefix = "cargo-git-";
  # 211 minus one for the `-` separator
  maxNameLen = 210;
in
{
  git,
  rev,
  ref ? null,
  hash ? null,
  allRefs ? ref == null,
}:
let
  maybeRef = lib.optionalAttrs (ref != null) { inherit ref; };
  repo =
    if hash == null then
      builtins.fetchGit (
        maybeRef
        // {
          inherit allRefs rev;
          url = git;
          submodules = true;
        }
      )
    else
      fetchgit {
        inherit rev hash;
        url = git;
        fetchSubmodules = true;
        fetchLFS = true;
      };

  remainingLen = maxNameLen - (lib.stringLength namePrefix) - (lib.stringLength rev);
  nameFromUrl =
    if (lib.stringLength git) > remainingLen then lib.substring 0 remainingLen git else git;
in
stdenv.mkDerivation {
  name = "${namePrefix}${nameFromUrl}-${rev}";
  src = repo;

  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  depsBuildBuild = [
    cargo
    craneUtils
    jq
    remarshal
    ripgrep
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
      local crateName=$(
        cargo metadata --format-version 1 --no-deps --manifest-path "$cargoToml" |
        jq -r '.packages[] | select(.manifest_path == "'"$cargoToml"'") | .name'
      )

      if [ -n "$crate" ]; then
        if [[ -n "''${existing_crates["$crate"]}" ]]; then
          >&2 echo "warning: skipping duplicate package $crate found at $cargoToml"
          continue
        fi

        local dest="$out/$crate"
        mkdir -p "$dest"

        # https://doc.rust-lang.org/cargo/reference/manifest.html#the-exclude-and-include-fields
        # Copy the crate's files. How this works:
        # Cargo allows specifying includes and excludes in Cargo.toml (if both are specified, only
        # includes is considered) for what files will be included when publishing or vendoring a
        # crate. The syntax follows gitignore style patterns which luckily ripgrep also understands.
        #
        # So we start out by peeking at the Cargo.toml for any includes, and we invert all rules
        # (since includes need to become not-excludes, and excludes remain as excludes). If includes
        # aren't defined, we can use the excludes as is (or fallback to nothing). Lastly we
        # force-include the Cargo.toml file since we know that must exist.
        #
        # Then we ask ripgrep to find all files for us and take the extra rules into account. This
        # additionally will automatically take .gitignore configurations into account since cargo
        # honors those as well. Note that we also specify --follow to ensure symlinks are followed
        # as well.
        #
        # Then we ensure all intermediate directories are created before copying the files over
        (
          cd "$(dirname "$cargoToml")"

          # Use `cargo package` to interpret the include/exclude rules
          #
          # XXX: throws errors on some crates, don't know why, is it the build-scripts?
          #
          # NB: `Cargo.lock` is excluded if it doesn't exist, because previous implementation
          # handled it that way. `cargo package` has other goals than us, maybe?
          crateFiles="$(cargo package --offline --exclude-lockfile -l -p "$crateName" | grep -v -e "^Cargo.toml.orig" $(if [[ ! -f Cargo.lock ]]; then echo "-e^Cargo.lock"; fi) | sort)"

          (
            cd "$dest"
            tr '\n' '\0' <<<"$crateFiles" \
              | xargs -0 -r -n1 dirname \
              | tr '\n' '\0' \
              | sort -z -u \
              | xargs -0 -r mkdir -p
          )
          tr '\n' '\0' <<<"$crateFiles" \
            | xargs -0 -r "-P''${NIX_BUILD_CORES:-1}" -I FILE cp -L FILE "$dest/FILE"
        )

        echo '{"files":{}, "package":null}' > "$dest/.cargo-checksum.json"

        crane-resolve-workspace-inheritance "$cargoToml" > "$dest/Cargo.toml.resolved" &&
          mv "$dest/Cargo.toml"{.resolved,}

        existing_crates["$crate"]='1'
      fi
    done

    runHook postInstall
  '';
}
