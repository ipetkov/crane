{ lib
, runCommandLocal
, vendorCargoRegistries
, vendorGitDeps
}:

{ cargoConfigs ? [ ]
, cargoLockContentsList ? [ ]
, cargoLockList ? [ ]
, cargoLockParsedList ? [ ]
}@args:
let
  inherit (builtins)
    attrNames
    attrValues
    fromTOML
    groupBy
    readFile;

  inherit (lib)
    concatMapStrings
    escapeShellArg;

  inherit (lib.attrsets)
    filterAttrs
    optionalAttrs;

  inherit (lib.lists)
    flatten
    unique;

  cargoLocksParsed = (map fromTOML ((map readFile cargoLockList) ++ cargoLockContentsList))
    ++ cargoLockParsedList;

  # Extract all packages from all Cargo.locks and trim any unused attributes from the parsed
  # data so we do not get any faux duplicates
  allowedAttrs = {
    name = true;
    version = true;
    source = true;
    checksum = true;
  };
  allPackagesTrimmed = map
    (l: map
      (filterAttrs (k: _: allowedAttrs.${k} or false))
      (l.package or [ ])
    )
    cargoLocksParsed;

  lockPackages = flatten (map unique (attrValues (groupBy
    (p: "${p.name}:${p.version}:${p.source or "local-path"}")
    (flatten allPackagesTrimmed)
  )));

  vendoredRegistries = vendorCargoRegistries ({
    inherit cargoConfigs lockPackages;
  } // optionalAttrs (args ? registries) { inherit (args) registries; });

  vendoredGit = vendorGitDeps {
    inherit lockPackages;
  };

  linkSources = sources: concatMapStrings
    (name: ''
      ln -s ${escapeShellArg sources.${name}} $out/${escapeShellArg name}
    '')
    (attrNames sources);
in
runCommandLocal "vendor-cargo-deps" { } ''
  mkdir -p $out
  cat >>$out/config.toml <<EOF
  ${vendoredRegistries.config}
  ${vendoredGit.config}
  EOF

  ${linkSources vendoredRegistries.sources}
  ${linkSources vendoredGit.sources}
''
