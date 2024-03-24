{ buildDepsOnly
, crateNameFromCargoToml
, mkCargoDerivation
, installFromCargoBuildLogHook
, removeReferencesToVendoredSourcesHook
, cargo-tauri
, writeText
, jq
, lib
, vendorCargoDeps
}:

{ pname ? null
, tauriConfigPath
, tauriDistDir
, tauriConfigOverride ? { }
, ...
}@origArgs:
let
  cleanedArgs = builtins.removeAttrs origArgs [
    "tauriConfigPath"
    "tauriConfigOverride"
    "tauriDistDir"
  ];

  origConfig = builtins.fromJSON (builtins.readFile tauriConfigPath);

  crateName = crateNameFromCargoToml cleanedArgs;

  buildConfig = lib.recursiveUpdate origConfig {
    package.productName = args.pname;
    build.distDir = tauriDistDir;
    build.beforeBuildCommand = "true";
    tauri.bundle.active = false;
  };

  overrridenConfig = lib.recursiveUpdate buildConfig tauriConfigOverride;

  # Avoid recomputing values when passing args down
  args = cleanedArgs // {
    pname = cleanedArgs.pname or crateName.pname;
    version = cleanedArgs.version or crateName.version;
    cargoVendorDir = cleanedArgs.cargoVendorDir or (vendorCargoDeps cleanedArgs);
  };
in
mkCargoDerivation (args // rec {
  cargoArtifacts = args.cargoArtifacts or (buildDepsOnly (args // {
    installCargoArtifactsMode = args.installCargoArtifactsMode or "use-zstd";
    doCheck = args.doCheck or false;
  }));


  buildPhaseCargoCommand = args.buildPhaseCommand or ''
    local profileArgs=""
    if [[ "$CARGO_PROFILE" == "release" ]]; then
      profileArgs="--release"
    fi
    cargoBuildLog=$(mktemp cargoBuildLogXXXX.json)
    cargo tauri build -c ${writeText "tauri.json" (builtins.toJSON overrridenConfig)} $profileArg -- --message-format json-render-diagnostics >"$cargoBuildLog"
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
    cargo-tauri installFromCargoBuildLogHook removeReferencesToVendoredSourcesHook jq
  ];
})
