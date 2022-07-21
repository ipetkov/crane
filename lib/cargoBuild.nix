{ buildDepsOnly
, crateNameFromCargoToml
, mkCargoDerivation
, vendorCargoDeps
}:

{ cargoBuildCommand ? "cargo build --release"
, cargoTestCommand ? "cargo test --release"
, cargoExtraArgs ? ""
, ...
}@args:
let
  crateName = crateNameFromCargoToml args;
  cleanedArgs = builtins.removeAttrs args [
    "cargoBuildCommand"
    "cargoExtraArgs"
    "cargoTestCommand"
  ];

  # Avoid recomputing values when passing args down
  memoizedArgs = {
    pname = args.pname or crateName.pname;
    version = args.version or crateName.version;

    # A directory of vendored cargo sources which can be consumed without network
    # access. Directory structure should basically follow the output of `cargo vendor`.
    # This can be inferred automatically if the `src` root has a Cargo.lock file.
    cargoVendorDir = args.cargoVendorDir or (vendorCargoDeps args);
  };
in
mkCargoDerivation (cleanedArgs // memoizedArgs // {
  doCheck = args.doCheck or true;

  # A directory to an existing cargo `target` directory, which will be reused
  # at the start of the derivation. Useful for caching incremental cargo builds.
  # This can be inferred automatically if the `src` root has both a Cargo.toml
  # and Cargo.lock file.
  cargoArtifacts = args.cargoArtifacts or (buildDepsOnly args // memoizedArgs);

  buildPhaseCargoCommand = args.buildPhaseCargoCommand or ''
    ${cargoBuildCommand} ${cargoExtraArgs}
  '';

  checkPhaseCargoCommand = args.checkPhaseCargoCommand or ''
    ${cargoTestCommand} ${cargoExtraArgs}
  '';
})
