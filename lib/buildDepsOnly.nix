{ crateNameFromCargoToml
, lib
, mkCargoDerivation
, mkDummySrc
, vendorCargoDeps
}:

{ cargoBuildCommand ? "cargoWithProfile build"
, cargoCheckCommand ? "cargoWithProfile check"
, cargoExtraArgs ? "--locked"
, cargoTestCommand ? "cargoWithProfile test"
, cargoTestExtraArgs ? "--no-run"
, ...
}@args:
let
  cleanedArgs = builtins.removeAttrs args [
    "cargoBuildCommand"
    "cargoCheckCommand"
    "cargoCheckExtraArgs"
    "cargoExtraArgs"
    "cargoTestCommand"
    "cargoTestExtraArgs"
    "outputHashes"
    "dummySrc"
    "outputs"
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

  # If dummySrc is define *in args*, use it as the `src` for fallback calculations,
  # but DO NOT use the computed `dummySrc` above as that's likely to trigger IFD
  # (in case anyone is trying to avoid that). Dummifiying the sources should preserve
  # the name/version of the Cargo.toml, as well as the entirety of Cargo.lock,
  # so it shouldn't matter anyway
  argsMaybeDummySrcOverride =
    if args ? dummySrc
    then args // { src = args.dummySrc; }
    else args;

  crateName = crateNameFromCargoToml argsMaybeDummySrcOverride;
in
mkCargoDerivation (cleanedArgs // {
  inherit doCheck;

  src = dummySrc;
  pnameSuffix = "-deps";
  pname = args.pname or crateName.pname;
  version = args.version or crateName.version;

  cargoArtifacts = null;
  cargoVendorDir = args.cargoVendorDir or (vendorCargoDeps argsMaybeDummySrcOverride);

  env = (args.env or { }) // {
    # Export a marker variable in case any scripts or hooks want to customize
    # how they run depending on if they are running here or with the "real"
    # project sources.
    # NB: *just* in case someone tries to set this to something specific, honor it
    CRANE_BUILD_DEPS_ONLY = args.env.CRANE_BUILD_DEPS_ONLY or 1;
  };

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
