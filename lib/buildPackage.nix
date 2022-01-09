{ cargoBuild
, installFromCargoBuildLogHook
, lib
}:

{ cargoBuildCommand ? "cargo build --workspace --release"
, cargoExtraArgs ? ""
, ...
}@args:
let
  buildPhaseCargoCommand = args.buildPhaseCargoCommand or ''
    cargoBuildLog=$(mktemp cargoBuildLogXXXX.json)
    ${cargoBuildCommand} --message-format json-render-diagnostics ${cargoExtraArgs} >"$cargoBuildLog"
  '';

  defaultInstallPhaseCommand = ''
    if [ -n "$cargoBuildLog" -a -f "$cargoBuildLog" ]; then
      installFromCargoBuildLog "$out" "$cargoBuildLog"
    else
      echo ${lib.strings.escapeShellArg ''
        !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        $cargoBuildLog is either undefined or does not point to a valid file location!
        By default `buildPackage` will capture cargo's output and use it to determine which binaries
        should be installed (instead of just guessing based on what is present in cargo's target directory).
        If you are overriding the derivation with a custom build step, you have two options:
        1. override `installPhaseCommand` with the appropriate installation steps
        2. ensure that cargo's build log is captured in a file and point $cargoBuildLog at it
        At a minimum, the latter option can be achieved with running:
            cargoBuildLog=$(mktemp cargoBuildLogXXXX.json)
            cargo build --message-format json-render-diagnostics >"$cargoBuildLog"
      ''}

      false
    fi
  '';

  installPhaseCommand =
    if args ? installPhaseCommand
    then ''
      echo running: ${lib.strings.escapeShellArg args.installPhaseCommand}
      ${args.installPhaseCommand}
    ''
    else defaultInstallPhaseCommand;
in
(cargoBuild args).overrideAttrs (old: {
  # NB: we use overrideAttrs here so that our extra additions here do not end up
  # invalidating any deps builds by being inherited. For example, we probably don't
  # care about installing bins/libs from the deps only build, so there's no point to
  # trying to build it with the install scripts in its build environment.

  # Don't copy target dir by default since we are going to be installing bins/libs
  doInstallCargoArtifacts = args.doInstallCargoArtifacts or false;

  buildPhase = args.buildPhase or ''
    runHook preBuild
    cargo --version
    echo running: ${lib.strings.escapeShellArg buildPhaseCargoCommand}
    ${buildPhaseCargoCommand}
    runHook postBuild
  '';

  installPhase = args.installPhase or ''
    runHook preInstall
    ${installPhaseCommand}
    runHook postInstall
  '';

  nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
    installFromCargoBuildLogHook
  ];
})
