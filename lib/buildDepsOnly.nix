{ crateNameFromCargoToml
, mkCargoDerivation
, mkDummySrc
, vendorCargoDepsFromArgs
}:

{ cargoExtraArgs ? ""
, cargoCheckCommand ? "cargo check --workspace --release"
, cargoBuildCommand ? "cargo build --workspace --release"
, cargoTestCommand ? "cargo test --workspace --release"
, ...
}@args:
let
  crateName = crateNameFromCargoToml args;
  cleanedArgs = builtins.removeAttrs args [
    "cargoBuildCommand"
    "cargoCheckCommand"
    "cargoExtraArgs"
    "cargoTestCommand"
  ];
in
mkCargoDerivation (cleanedArgs // {
  src = mkDummySrc args;
  pnameSuffix = "-deps";
  pname = args.pname or crateName.pname;
  version = args.version or crateName.version;

  cargoArtifacts = null;
  cargoVendorDir = args.cargoVendorDir or (vendorCargoDepsFromArgs args);

  # First we run `cargo check` to cache cargo's internal artifacts, fingerprints, etc. for all deps.
  # Then we run `cargo build` to actually compile the deps and cache the results
  buildPhaseCargoCommand = args.buildPhaseCargoCommand or ''
    ${cargoCheckCommand} ${cargoExtraArgs}
    ${cargoBuildCommand} ${cargoExtraArgs}
  '';

  checkPhaseCargoCommand = args.checkPhaseCargoCommand or ''
    ${cargoTestCommand} ${cargoExtraArgs}
  '';

  # Run tests by default to ensure we cache any dev-dependencies
  doCheck = args.doCheck or true;

  # No point in building this if not for the cargo artifacts
  doInstallCargoArtifacts = true;
})
