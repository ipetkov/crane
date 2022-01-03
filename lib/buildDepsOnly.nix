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
in
mkCargoDerivation (args // {
  src = mkDummySrc args;
  pname = args.pname or "${crateName.pname}-deps";
  version = args.version or crateName.version;

  cargoArtifacts = null;
  cargoVendorDir = args.cargoVendorDir or vendorCargoDepsFromArgs args;

  # First we run `cargo check` to cache cargo's internal artifacts, fingerprints, etc. for all deps.
  # Then we run `cargo build` to actually compile the deps and cache the results
  buildPhaseCargoCommand = args.buildPhaseCargoCommand or ''
    ${cargoCheckCommand} ${cargoExtraArgs}
    ${cargoBuildCommand} ${cargoExtraArgs}
  '';

  checkPhaseCargoCommand = args.checkPhaseCargoCommand or ''
    ${cargoTestCommand} ${cargoExtraArgs}
  '';

  # No point in building this if not for the cargo artifacts
  doCopyTargetToOutput = true;

  # By default, don't install anything (else, besides the cargo target directory),
  # but let the caller set their own if they wish
  installPhaseCargoCommand = args.installPhaseCargoCommand or ''
    mkdir -p $out
  '';
})
