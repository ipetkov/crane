{ cargo
, configureCargoCommonVarsHook
, configureCargoVendoredDepsHook
, copyCargoTargetToOutputHook
, inheritCargoTargetHook
, lib
, stdenv
, vendorCargoDeps
}:

{ doCompressTarget ? true
, doCopyTarget ? true
, nativeBuildInputs ? [ ]
, outputs ? [ "out" ]
, ...
}@args:
let
  vendorFromCargoLockPath = path:
    let
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
      '';

  defaultValues = {
    inherit
      doCompressTarget
      doCopyTarget;

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

    cargoVendorDir =
      if args ? src
      then vendorFromCargoLockPath args.src
      else null;
  };

  additions = {
    outputs = outputs ++ lib.optional doCopyTarget "target";

    nativeBuildInputs = nativeBuildInputs ++ [
      cargo
      configureCargoCommonVarsHook
      configureCargoVendoredDepsHook
      copyCargoTargetToOutputHook
      inheritCargoTargetHook
    ];
  };
in
stdenv.mkDerivation (defaultValues // args // additions)
