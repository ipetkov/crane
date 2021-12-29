{ cargo
, configureCargoCommonVarsHook
, configureCargoVendoredDepsHook
, copyCargoTargetToOutputHook
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
        cargoLock = path + "/Cargo.lock";
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
in

{
  # A directory to an existing cargo `target` directory, which will be reused
  # at the start of the derivation. Useful for caching incremental cargo builds
  cargoArtifacts ? null
  # A directory of vendored cargo sources which can be consumed without network
  # access. Directory structure should basically follow the output of `cargo vendor`
, cargoVendorDir ? vendorCargoDepsFromArgs args
  # Controls whether cargo's `target` directory should be compressed when copied
  # to the output at the end of the derivation.
, doCompressTarget ? true
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
  defaultValues = {
    inherit
      cargoVendorDir
      doCompressTarget
      doCopyTargetToOutput
      doRemapSourcePathPrefix;

    buildPhase = ''
      runHook preBuild
      cargo build --release
      runHook postBuild
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
