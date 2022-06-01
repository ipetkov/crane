{ findCargoFiles
, lib
, runCommandLocal
, vendorCargoRegistries
, vendorGitDeps
}:

args:
let
  inherit (builtins)
    attrNames
    pathExists
    readFile;

  inherit (lib)
    concatMapStrings
    escapeShellArg;

  src = args.src or (throw ''
    unable to find `src` attribute. consider one of the following:
    - set `cargoVendorDir = vendorCargoDeps { cargoLock = ./some/path/to/Cargo.lock; }`
    - set `cargoVendorDir = vendorCargoDeps { src = ./src/containing/cargo/lock/file; }`
    - set `cargoVendorDir = null` to skip vendoring altogether
  '');

  cargoLock = args.cargoLock or (src + "/Cargo.lock");
  cargoLockContents = args.cargoLockContents or (
    if pathExists cargoLock
    then readFile cargoLock
    else
      throw ''
        unable to find Cargo.lock at ${src}. please ensure one of the following:
        - a Cargo.lock exists at the root of the source directory of the derivation
        - set `cargoVendorDir = vendorCargoDeps { cargoLock = ./some/path/to/Cargo.lock; }`
        - set `cargoVendorDir = vendorCargoDeps { src = ./src/containing/cargo/lock/file; }`
        - set `cargoVendorDir = null` to skip vendoring altogether
      ''
  );

  linkSources = sources: concatMapStrings
    (name: ''
      ln -s ${escapeShellArg sources.${name}} $out/${escapeShellArg name}
    '')
    (attrNames sources);

  lock = builtins.fromTOML cargoLockContents;
  lockPackages = lock.package or (throw "Cargo.lock missing [[package]] definitions");

  vendoredRegistries = vendorCargoRegistries {
    inherit lockPackages;
    cargoConfigs = (findCargoFiles src).cargoConfigs;
  };
  vendoredGit = vendorGitDeps {
    inherit lockPackages;
  };
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
