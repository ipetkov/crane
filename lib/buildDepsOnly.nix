{ crateNameFromCargoToml
, lib
, mkCargoDerivation
, mkDummySrc
, vendorCargoDeps
}:

{ cargoBuildCommand ? "cargoWithProfile build"
, cargoCheckCommand ? "cargoWithProfile check"
, cargoExtraArgs ? ""
, cargoTestCommand ? "cargoWithProfile test"
, cargoTestExtraArgs ? ""
, ...
}@args:
let
  crateName = crateNameFromCargoToml args;
  cleanedArgs = builtins.removeAttrs args [
    "cargoBuildCommand"
    "cargoCheckCommand"
    "cargoCheckExtraArgs"
    "cargoExtraArgs"
    "cargoTestCommand"
    "cargoTestExtraArgs"
    "dummySrc"
  ];

  # Run tests by default to ensure we cache any dev-dependencies
  doCheck = args.doCheck or true;

  cargoCheckExtraArgs = args.cargoCheckExtraArgs or (if doCheck then "--all-targets" else "");

  dummySrc =
    if args ? dummySrc then
      lib.warnIf
        (args ? src && args.src != null)
        "buildDepsOnly will ignore `src` when `dummySrc` is specified"
        args.dummySrc
    else
      mkDummySrc args;
in
mkCargoDerivation (cleanedArgs // {
  inherit doCheck;

  src = dummySrc;
  pnameSuffix = "-deps";
  pname = args.pname or crateName.pname;
  version = args.version or crateName.version;

  cargoArtifacts = null;
  cargoVendorDir = args.cargoVendorDir or (vendorCargoDeps args);

  # First we run `cargo check` to cache cargo's internal artifacts, fingerprints, etc. for all deps.
  # Then we run `cargo build` to actually compile the deps and cache the results
  buildPhaseCargoCommand = args.buildPhaseCargoCommand or ''
    ${cargoCheckCommand} ${cargoExtraArgs} ${cargoCheckExtraArgs}
    ${cargoBuildCommand} ${cargoExtraArgs}
  '';

  checkPhaseCargoCommand = args.checkPhaseCargoCommand or ''
    ${cargoTestCommand} ${cargoExtraArgs} ${cargoTestExtraArgs}
  '';

  # No point in building this if not for the cargo artifacts
  doInstallCargoArtifacts = true;
})
