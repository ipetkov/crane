{ cargo
, cargoHelperFunctionsHook
, configureCargoCommonVarsHook
, configureCargoVendoredDepsHook
, crateNameFromCargoToml
, mkCrossToolchainEnv
, inheritCargoArtifactsHook
, installCargoArtifactsHook
, lib
, replaceCargoLockHook
, rustc
, rsync
, vendorCargoDeps
, writeText
, writeTOML
, zstd
, pkgs
}:

args@{
  # A directory to an existing cargo `target` directory, which will be reused
  # at the start of the derivation. Useful for caching incremental cargo builds.
  cargoArtifacts
  # A command (likely a cargo invocation) to run during the derivation's build
  # phase. Pre and post build hooks will automatically be run.
, buildPhaseCargoCommand
  # A command (likely a cargo invocation) to run during the derivation's check
  # phase. Pre and post check hooks will automatically be run.
, checkPhaseCargoCommand ? ""
  # A command  to run during the derivation's install
  # phase. Pre and post install hooks will automatically be run.
, installPhaseCommand ? "mkdir -p $out"
, ...
}:
let
  # Warn if an stdenv selector function is required (e.g. when cross compiling) while only a single stdenv instance is given
  stdenvSelectorWarnMsg = ''
    mkCargoDerivation's stdenv argument was set to a specific stdenv instance
    while an stdenv selector function is required. Consider specifying a
    function which selects an stdenv for any given `pkgs` instantiation:

    {
      ...
      stdenv = p: p.clangStdenv;
      ...
    }
  '';

  stdenvSelector =
    if args ? stdenv && lib.isFunction args.stdenv then args.stdenv
    else lib.warnIf (args ? stdenv) stdenvSelectorWarnMsg (p: p.stdenv);

  chosenStdenv =
    if args ? stdenv && !(lib.isFunction args.stdenv) then args.stdenv
    else stdenvSelector pkgs;

  crateName = crateNameFromCargoToml args;
  cleanedArgs = builtins.removeAttrs args [
    "buildPhaseCargoCommand"
    "cargoLock"
    "cargoLockContents"
    "cargoLockParsed"
    "checkPhaseCargoCommand"
    "installPhaseCommand"
    "pnameSuffix"
    "outputHashes"
    "stdenv"
  ];

  cargoLockFromContents =
    if args ? cargoLockContents
    then writeText "Cargo.lock" args.cargoLockContents
    else if args ? cargoLockParsed
    then writeTOML "Cargo.lock" args.cargoLockParsed
    else null;
  cargoLock = args.cargoLock or cargoLockFromContents;
in
chosenStdenv.mkDerivation (
  lib.optionalAttrs (!(args.noCrossToolchainEnv or false)) (mkCrossToolchainEnv stdenvSelector)
  // cleanedArgs
  // lib.optionalAttrs (cargoLock != null) { inherit cargoLock; }
  // {
  inherit cargoArtifacts;

  pname = "${args.pname or crateName.pname}${args.pnameSuffix or ""}";
  version = args.version or crateName.version;

  # Controls whether cargo's `target` directory should be copied as an output
  doInstallCargoArtifacts = args.doInstallCargoArtifacts or true;

  # A directory of vendored cargo sources which can be consumed without network
  # access. Directory structure should basically follow the output of `cargo vendor`.
  cargoVendorDir = args.cargoVendorDir or (vendorCargoDeps args);

  nativeBuildInputs = (args.nativeBuildInputs or [ ]) ++ [
    cargo
    cargoHelperFunctionsHook
    configureCargoCommonVarsHook
    configureCargoVendoredDepsHook
    inheritCargoArtifactsHook
    installCargoArtifactsHook
    replaceCargoLockHook
    rsync
    rustc
    zstd
  ];

  buildPhase = args.buildPhase or ''
    runHook preBuild
    cargo --version
    ${buildPhaseCargoCommand}
    runHook postBuild
  '';

  checkPhase = args.checkPhase or ''
    runHook preCheck
    ${checkPhaseCargoCommand}
    runHook postCheck
  '';

  configurePhase = args.configurePhase or ''
    runHook preConfigure
    echo default configurePhase, nothing to do
    runHook postConfigure
  '';

  installPhase = args.installPhase or ''
    runHook preInstall
    ${installPhaseCommand}
    runHook postInstall
  '';
})
