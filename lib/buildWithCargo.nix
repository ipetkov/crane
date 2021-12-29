{ cargo
, configureCargoCommonVarsHook
, configureCargoVendoredDepsHook
, copyCargoTargetToOutputHook
, inheritCargoArtifactsHook
, lib
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

{ cargoArtifacts ? null
, cargoVendorDir ? vendorCargoDepsFromArgs args
, doCompressTarget ? true
, doCopyTargetToOutput ? true
, nativeBuildInputs ? [ ]
, outputs ? [ "out" ]
, ...
}@args:
let
  defaultValues = {
    inherit
      cargoVendorDir
      doCompressTarget
      doCopyTargetToOutput;

    buildPhase = ''
      runHook preBuild
      cargo check --release
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      runHook postInstall
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
    ];
  };
in
stdenv.mkDerivation (defaultValues // args // additions)
