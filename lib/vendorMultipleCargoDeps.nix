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
    optionalAttrs;

  inherit (lib.lists)
    flatten
    unique;

  cargoLocksParsed = (map fromTOML ((map readFile cargoLockList) ++ cargoLockContentsList))
    ++ cargoLockParsedList;
  lockPackages = flatten (map unique (attrValues (groupBy
    (p: "${p.name}:${p.version}:${p.source or "local-path"}")
    (flatten (map (l: l.package or [ ]) cargoLocksParsed))
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
