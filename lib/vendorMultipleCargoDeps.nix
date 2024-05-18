{ lib
, pkgsBuildBuild
, vendorCargoRegistries
, vendorGitDeps
}:

let
  inherit (pkgsBuildBuild)
    runCommandLocal;

  inherit (builtins)
    attrNames
    attrValues
    fromTOML
    readFile;

  inherit (lib)
    concatMapStrings
    escapeShellArg
    groupBy;

  inherit (lib.attrsets)
    filterAttrs
    optionalAttrs;

  inherit (lib.lists)
    flatten
    unique;
in
{ cargoConfigs ? [ ]
, cargoLockContentsList ? [ ]
, cargoLockList ? [ ]
, cargoLockParsedList ? [ ]
, outputHashes ? { }
, overrideVendorCargoPackage ? _: drv: drv
, overrideVendorGitCheckout ? _: drv: drv
, registries ? null
}:
let
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
      ((l.package or [ ]) ++ (l.patch.unused or [ ]))
    )
    cargoLocksParsed;

  lockPackages = flatten (map unique (attrValues (groupBy
    (p: "${p.name}:${p.version}:${p.source or "local-path"}")
    (flatten allPackagesTrimmed)
  )));

  vendoredRegistries = vendorCargoRegistries ({
    inherit cargoConfigs lockPackages overrideVendorCargoPackage;
  } // optionalAttrs (registries != null) { inherit registries; });

  vendoredGit = vendorGitDeps {
    inherit lockPackages outputHashes overrideVendorGitCheckout;
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
