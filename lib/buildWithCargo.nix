{ buildDepsOnly
, cargo
, configureCargoCommonVarsHook
, configureCargoVendoredDepsHook
, copyCargoTargetToOutputHook
, crateNameFromCargoToml
, inheritCargoArtifactsHook
, installFromCargoArtifactsHook
, lib
, remapSourcePathPrefixHook
, stdenv
, vendorCargoDeps
}:
let
  vendorCargoDepsFromArgs = args:
    if args ? src
    then
      let
        path = args.src;
        cargoLock = path + /Cargo.lock;
      in
      if builtins.pathExists cargoLock
      then vendorCargoDeps { inherit cargoLock; }
      else
        throw ''
          unable to find Cargo.lock at ${path}. please ensure one of the following:
          - a Cargo.lock exists at the root of the source directory of the derivation
          - set `cargoVendorDir = vendorCargoDeps { cargoLock = ./some/path/to/Cargo.lock; }`
          - set `cargoVendorDir = null` to skip vendoring altogether
        ''
    else null;

  cargoArtifactsFromArgs = args:
    if args ? src
    then
      let
        path = args.src;
        cargoToml = path + /Cargo.toml;
        cargoLock = path + /Cargo.lock;
      in
      if builtins.pathExists cargoToml && builtins.pathExists cargoLock
      then (buildDepsOnly args).target
      else
        throw ''
          unable to find Cargo.toml and Cargo.lock at ${path}. please ensure one of the following:
          - a Cargo.toml and Cargo.lock exists at the root of the source directory of the derivation
          - set `cargoArtifacts = buildDepsOnly { src = ./some/path/to/cargo/root; }`
          - set `cargoArtifacts = null` to skip reusing cargo artifacts altogether
        ''
    else null;
in

{
  # A directory to an existing cargo `target` directory, which will be reused
  # at the start of the derivation. Useful for caching incremental cargo builds.
  # This can be inferred automatically if the `src` root has both a Cargo.toml
  # and Cargo.lock file.
  cargoArtifacts ? cargoArtifactsFromArgs args
  # A directory of vendored cargo sources which can be consumed without network
  # access. Directory structure should basically follow the output of `cargo vendor`.
  # This can be inferred automatically if the `src` root has a Cargo.lock file.
, cargoVendorDir ? vendorCargoDepsFromArgs args
  # Controls whether cargo's `target` directory should be copied as an output
, doCopyTargetToOutput ? true
  # Controls instructing rustc to remap the path prefix of any sources it
  # captures (for example, this can include file names in panic info). This is
  # useful to omit any references to `/nix/store/...` from the final binary,
  # as including them will make Nix pull in all sources when installing any binaries.
, doRemapSourcePathPrefix ? true
, nativeBuildInputs ? [ ]
, outputs ? [ "out" ]
, ...
}@args:
let
  defaultValues = (crateNameFromCargoToml args) // {
    inherit
      cargoArtifacts
      cargoVendorDir
      doCopyTargetToOutput
      doRemapSourcePathPrefix;

    buildPhase = ''
      runHook preBuild
      cargo build --workspace --release
      runHook postBuild
    '';

    checkPhase = ''
      runHook preCheck
      cargo test --workspace --release
      runHook postCheck
    '';
  };

  additions = {
    outputs = outputs ++ lib.optional doCopyTargetToOutput "target";

    nativeBuildInputs = nativeBuildInputs ++ [
      cargo
      configureCargoCommonVarsHook
      configureCargoVendoredDepsHook
      copyCargoTargetToOutputHook
      inheritCargoArtifactsHook
      installFromCargoArtifactsHook
      remapSourcePathPrefixHook
    ];
  };
in
stdenv.mkDerivation (defaultValues // args // additions)
