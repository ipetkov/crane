{
  lib,
  binaryen,
  buildDepsOnly,
  crateNameFromCargoToml,
  mkCargoDerivation,
  dart-sass,
  removeReferencesToVendoredSourcesHook,
  removeReferencesToRustToolchainHook,
  trunk,
  vendorCargoDeps,
  wasm-bindgen-cli,
}:

let
  missingWasmBindgenCliPkgMessage = ''
    Unstable usage of buildTrunkPackage!

    The version of the tool `wasm-bindgen-cli` (Package used during compilation)
    must match the version of the `wasm-bindgen` (Rust library, check your Cargo.lock),
    buildTrunkPackage now requires the argument wasm-bindgen-cli:

    buildTrunkPackage {
      wasm-bindgen-cli = pkgs.wasm-bindgen-cli.override {
        version = "${default-wasm-bindgen-cli.version}";
        hash = "${default-wasm-bindgen-cli.hash or "lib.fakeHash"}";
        cargoHash = "${default-wasm-bindgen-cli.cargoHash or "lib.fakeHash"}";
      };
      ...
    }
  '';
  default-wasm-bindgen-cli = wasm-bindgen-cli;
in

{
  trunkExtraArgs ? "",
  trunkExtraBuildArgs ? "",
  trunkIndexPath ? "./index.html",
  wasm-bindgen-cli ? lib.warn missingWasmBindgenCliPkgMessage default-wasm-bindgen-cli,
  ...
}@origArgs:
let
  cleanedArgs = builtins.removeAttrs origArgs [
    "trunkExtraArgs"
    "trunkExtraBuildArgs"
    "trunkIndexPath"
    "wasm-bindgen-cli"
  ];

  crateName = crateNameFromCargoToml cleanedArgs;

  # Avoid recomputing values when passing args down
  args = cleanedArgs // {
    pname = cleanedArgs.pname or crateName.pname;
    version = cleanedArgs.version or crateName.version;
    cargoVendorDir = cleanedArgs.cargoVendorDir or (vendorCargoDeps cleanedArgs);
  };
in
mkCargoDerivation (
  args
  // {
    pnameSuffix = "-trunk";

    cargoArtifacts =
      args.cargoArtifacts or (buildDepsOnly (
        args
        // {
          CARGO_BUILD_TARGET = args.CARGO_BUILD_TARGET or "wasm32-unknown-unknown";
          doCheck = args.doCheck or false;
        }
      ));

    env.TRUNK_SKIP_VERSION_CHECK = args.env.TRUNK_SKIP_VERSION_CHECK or "true";

    # Force trunk to not download dependencies, but set the version with
    # whatever tools actually make it into the builder's PATH
    preConfigure = ''
      echo configuring trunk tools
      TRUNK_TOOLS_SASS=$(sass --version | head -n1)
      TRUNK_TOOLS_WASM_BINDGEN=$(wasm-bindgen --version | cut -d' ' -f2)
      TRUNK_TOOLS_WASM_OPT="version_$(wasm-opt --version | cut -d' ' -f3)"
      export TRUNK_TOOLS_SASS
      export TRUNK_TOOLS_WASM_BINDGEN
      export TRUNK_TOOLS_WASM_OPT

      echo "TRUNK_TOOLS_SASS=''${TRUNK_TOOLS_SASS}"
      echo "TRUNK_TOOLS_WASM_BINDGEN=''${TRUNK_TOOLS_WASM_BINDGEN}"
      echo "TRUNK_TOOLS_WASM_OPT=''${TRUNK_TOOLS_WASM_OPT}"
    '';

    buildPhaseCargoCommand =
      args.buildPhaseCargoCommand or ''
        local profileArgs=""
        if [[ "$CARGO_PROFILE" == "release" ]]; then
          profileArgs="--release${lib.optionalString (lib.versionAtLeast trunk.version "0.21") "=true"}"
        fi

        trunk ${trunkExtraArgs} build $profileArgs ${trunkExtraBuildArgs} "${trunkIndexPath}"
      '';

    installPhaseCommand =
      args.installPhaseCommand or ''
        cp -r "$(dirname "${trunkIndexPath}")/dist" $out
      '';

    # Installing artifacts on a distributable dir does not make much sense
    doInstallCargoArtifacts = args.doInstallCargoArtifacts or false;

    nativeBuildInputs = (args.nativeBuildInputs or [ ]) ++ [
      binaryen
      dart-sass
      trunk
      wasm-bindgen-cli
      # Store references are certainly false positives
      removeReferencesToRustToolchainHook
      removeReferencesToVendoredSourcesHook
    ];
  }
)
