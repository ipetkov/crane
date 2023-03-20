{ cargo
, cargoHelperFunctionsHook
, configureCargoCommonVarsHook
, configureCargoVendoredDepsHook
, crateNameFromCargoToml
, inheritCargoArtifactsHook
, installCargoArtifactsHook
, stdenv
, vendorCargoDeps
, zstd
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
  crateName = crateNameFromCargoToml args;
  chosenStdenv = args.stdenv or stdenv;
  cleanedArgs = builtins.removeAttrs args [
    "buildPhaseCargoCommand"
    "cargoLock"
    "cargoLockContents"
    "cargoLockParsed"
    "checkPhaseCargoCommand"
    "installPhaseCommand"
    "pnameSuffix"
    "stdenv"
  ];
in
chosenStdenv.mkDerivation (cleanedArgs // {
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
