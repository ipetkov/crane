{ buildDepsOnly
, crateNameFromCargoToml
, installFromCargoBuildLogHook
, lib
, mkCargoDerivation
, removeReferencesToVendoredSourcesHook
, vendorCargoDeps
}:

{ cargoBuildCommand ? "cargoWithProfile build"
, cargoExtraArgs ? "--locked"
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
    "outputHashes"
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
    buildDepsOnly (args // memoizedArgs // {
      # NB: we intentionally don't run any caller-provided hooks here since they might fail
      # if they require any files that have been omitted by the source dummification.
      # However, we still _do_ want to run the installation hook with the actual artifacts
      installPhase = "prepareAndInstallCargoArtifactsDir";
    })
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
    # NB: avoid adding any non-hook packages here. Doing so will end up
    # changing PKG_CONFIG_PATH and cause rebuilds of `*-sys` crates.
    installFromCargoBuildLogHook
    removeReferencesToVendoredSourcesHook
  ];
})
