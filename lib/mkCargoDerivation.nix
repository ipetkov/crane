{ cargo
, cargoHelperFunctionsHook
, configureCargoCommonVarsHook
, configureCargoVendoredDepsHook
, crateNameFromCargoToml
, inheritCargoArtifactsHook
, installCargoArtifactsHook
, rsync
, stdenv
, vendorCargoDeps
, writeShellApplication
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

  rustcWrapper = writeShellApplication {
    name = "rustc-wrapper";
    text = ''
      set -euo pipefail

      args=("$@")

      temp_dir=$(mktemp -d)
      trap 'rm -rf -- "$temp_dir"' EXIT

      for i in "''${!args[@]}"; do
        if [[ "''${args[i]}" == --out-dir=* ]]; then
          current_out_dir="''${args[i]#--out-dir=}"
          args[i]="--out-dir=$temp_dir"
          break
        elif [[ "''${args[i]}" == --out-dir ]]; then
          current_out_dir="''${args[i+1]}"
          args[i+1]="$temp_dir"
          break
        fi
      done

      if [[ -v current_out_dir ]]; then
        stderr="$temp_dir/crane_stderr"
        set +e
        stdout=$("''${args[@]}" 2>"$stderr")
        exit_code=$?
        set -e
        stderr_text=$(cat "$stderr")
        rm "$stderr"
        cp -r "$temp_dir/." "$current_out_dir"
        echo -n "$stdout"
        echo -n "$stderr_text" >&2
        exit $exit_code
      else
        exec "$@"
      fi
    '';
  };
in
chosenStdenv.mkDerivation (cleanedArgs // {
  inherit cargoArtifacts;

  pname = "${args.pname or crateName.pname}${args.pnameSuffix or ""}";
  version = args.version or crateName.version;

  RUSTC_WRAPPER="${rustcWrapper}/bin/rustc-wrapper";

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
    rsync
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
