{ buildDepsOnly
, crateNameFromCargoToml
, installFromCargoBuildLogHook
, jq
, lib
, mkCargoDerivation
, removeReferencesToVendoredSourcesHook
, vendorCargoDeps
}:

{ cargoBuildCommand ? "cargoWithProfile build"
, cargoExtraArgs ? ""
, cargoTestCommand ? "cargoWithProfile test"
, cargoTestExtraArgs ? ""
, ...
}@args:
let
  inherit (builtins) removeAttrs;

  crateName = crateNameFromCargoToml args;
  cleanedArgs = removeAttrs args [
    "cargoBuildCommand"
    "cargoExtraArgs"
    "cargoTestCommand"
    "cargoTestExtraArgs"
  ];

  # Avoid recomputing values when passing args down
  memoizedArgs = {
    pname = args.pname or crateName.pname;
    version = args.version or crateName.version;
    cargoVendorDir = args.cargoVendorDir or (vendorCargoDeps args);
  };
in
mkCargoDerivation (cleanedArgs // memoizedArgs // {
  doCheck = args.doCheck or true;
  doInstallCargoArtifacts = args.doInstallCargoArtifacts or false;

  cargoArtifacts = args.cargoArtifacts or (
    let
      depsArgs = args // memoizedArgs // {
        installCargoArtifactsMode = args.installCargoArtifactsMode or "use-zstd";
      };
    in
    buildDepsOnly (removeAttrs depsArgs [ "installPhase" "installPhaseCommand" ])
  );

  buildPhaseCargoCommand = args.buildPhaseCargoCommand or ''
    cargoBuildLog=$(mktemp cargoBuildLogXXXX.json)
    ${cargoBuildCommand} --message-format json-render-diagnostics ${cargoExtraArgs} >"$cargoBuildLog"
  '';

  checkPhaseCargoCommand = args.checkPhaseCargoCommand or ''
    ${cargoTestCommand} ${cargoExtraArgs} ${cargoTestExtraArgs}
  '';

  installPhaseCommand = args.installPhaseCommand or ''
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
            cargo build --release --message-format json-render-diagnostics >"$cargoBuildLog"
      ''}

      false
    fi
  '';

  nativeBuildInputs = (args.nativeBuildInputs or [ ]) ++ [
    installFromCargoBuildLogHook
    jq
    removeReferencesToVendoredSourcesHook
  ];
})
