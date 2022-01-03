{ buildDepsOnly
, crateNameFromCargoToml
, installFromCargoArtifactsHook
, mkCargoDerivation
, vendorCargoDepsFromArgs
}:
let
  cargoArtifactsFromArgs = args:
    if args ? src
    then
      let
        path = args.src;
        cargoToml = path + /Cargo.toml;
        cargoLock = path + /Cargo.lock;
      in
      if builtins.pathExists cargoToml && builtins.pathExists cargoLock
      then buildDepsOnly args
      else
        throw ''
          unable to find Cargo.toml and Cargo.lock at ${path}. please ensure one of the following:
          - a Cargo.toml and Cargo.lock exists at the root of the source directory of the derivation
          - set `cargoArtifacts = buildDepsOnly { src = ./some/path/to/cargo/root; }`
          - set `cargoArtifacts = null` to skip reusing cargo artifacts altogether
        ''
    else null;
in

{ cargoBuildCommand ? "cargo build --workspace --release"
, cargoTestCommand ? "cargo test --workspace --release"
, cargoExtraArgs ? ""
, ...
}@args:
let
  crateName = crateNameFromCargoToml args;
in
mkCargoDerivation (args // {
  pname = args.pname or crateName.pname;
  version = args.version or crateName.version;

  # A directory to an existing cargo `target` directory, which will be reused
  # at the start of the derivation. Useful for caching incremental cargo builds.
  # This can be inferred automatically if the `src` root has both a Cargo.toml
  # and Cargo.lock file.
  cargoArtifacts = args.cargoArtifacts or (cargoArtifactsFromArgs args);

  # A directory of vendored cargo sources which can be consumed without network
  # access. Directory structure should basically follow the output of `cargo vendor`.
  # This can be inferred automatically if the `src` root has a Cargo.lock file.
  cargoVendorDir = args.cargoVendorDir or (vendorCargoDepsFromArgs args);

  nativeBuildInputs = (args.nativeBuildInputs or [ ]) ++ [
    installFromCargoArtifactsHook
  ];

  buildPhaseCargoCommand = args.buildPhaseCargoCommand or ''
    ${cargoBuildCommand} ${cargoExtraArgs}
  '';

  checkPhaseCargoCommand = args.checkPhaseCargoCommand or ''
    ${cargoTestCommand} ${cargoExtraArgs}
  '';

  installPhaseCargoCommand = args.installPhaseCargoCommand or ''
    installFromCargoArtifacts
  '';
})
