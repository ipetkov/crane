{ crateNameFromCargoToml
, mkCargoDerivation
, mkDummySrc
, vendorCargoDeps
}:

{ cargoBuildCommand ? "cargoWithProfile build"
, cargoCheckCommand ? "cargoWithProfile check --all-targets"
, cargoExtraArgs ? ""
, cargoTestCommand ? "cargoWithProfile test"
, ...
}@args:
let
  crateName = crateNameFromCargoToml args;
  cleanedArgs = builtins.removeAttrs args [
    "cargoBuildCommand"
    "cargoCheckCommand"
    "cargoExtraArgs"
    "cargoTestCommand"
    "dummySrc"
  ];

  throwMsg = throw ''
    unable to find Cargo.toml and Cargo.lock at ${path}. please ensure one of the following:
    - a Cargo.toml and Cargo.lock exists at the root of the source directory of the derivation
    - set `cargoArtifacts = buildDepsOnly { src = ./some/path/to/cargo/root; }`
    - set `cargoArtifacts = null` to skip reusing cargo artifacts altogether
  '';

  path = args.src or throwMsg;
  cargoToml = path + "/Cargo.toml";
  dummySrc = args.dummySrc or
    (if builtins.pathExists cargoToml
    then mkDummySrc args
    else throwMsg);
in
mkCargoDerivation (cleanedArgs // {
  src = dummySrc;
  pnameSuffix = "-deps";
  pname = args.pname or crateName.pname;
  version = args.version or crateName.version;

  cargoArtifacts = null;
  cargoVendorDir = args.cargoVendorDir or (vendorCargoDeps args);

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
