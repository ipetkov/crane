{ cargo
, configureCargoCommonVarsHook
, configureCargoVendoredDepsHook
, inheritCargoArtifactsHook
, installCargoTargetDirHook
, lib
, remapSourcePathPrefixHook
, stdenv
}:

args@{
  # A directory to an existing cargo `target` directory, which will be reused
  # at the start of the derivation. Useful for caching incremental cargo builds.
  cargoArtifacts
  # A directory of vendored cargo sources which can be consumed without network
  # access. Directory structure should basically follow the output of `cargo vendor`.
, cargoVendorDir
  # A command (likely a cargo invocation) to run during the derivation's build
  # phase. Pre and post build hooks will automatically be run.
, buildPhaseCargoCommand
  # A command (likely a cargo invocation) to run during the derivation's check
  # phase. Pre and post check hooks will automatically be run.
, checkPhaseCargoCommand
  # A command  to run during the derivation's install
  # phase. Pre and post install hooks will automatically be run.
, installPhaseCommand ? "mkdir -p $out"
, ...
}:
let
  cleanedArgs = builtins.removeAttrs args [
    "buildPhaseCargoCommand"
    "checkPhaseCargoCommand"
    "installPhaseCommand"
    "pnameSuffix"
  ];
in
stdenv.mkDerivation (cleanedArgs // {
  pname = "${args.pname}${args.pnameSuffix or ""}";

  # Controls whether cargo's `target` directory should be copied as an output
  doCopyTargetToOutput = args.doCopyTargetToOutput or true;

  # Controls instructing rustc to remap the path prefix of any sources it
  # captures (for example, this can include file names in panic info). This is
  # useful to omit any references to `/nix/store/...` from the final binary,
  # as including them will make Nix pull in all sources when installing any binaries.
  doRemapSourcePathPrefix = args.doRemapSourcePathPrefix or true;

  nativeBuildInputs = (args.nativeBuildInputs or [ ]) ++ [
    cargo
    configureCargoCommonVarsHook
    configureCargoVendoredDepsHook
    inheritCargoArtifactsHook
    installCargoTargetDirHook
    remapSourcePathPrefixHook
  ];

  buildPhase = args.buildPhase or ''
    runHook preBuild
    echo running: ${lib.strings.escapeShellArg buildPhaseCargoCommand}
    ${buildPhaseCargoCommand}
    runHook postBuild
  '';

  checkPhase = args.checkPhase or ''
    runHook preCheck
    echo running: ${lib.strings.escapeShellArg checkPhaseCargoCommand}
    ${checkPhaseCargoCommand}
    runHook postCheck
  '';

  installPhase = args.installPhase or ''
    runHook preInstall
    echo running: ${lib.strings.escapeShellArg installPhaseCommand}
    ${installPhaseCommand}
    runHook postInstall
  '';
})
