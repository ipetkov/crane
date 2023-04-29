{ binaryen
, buildDepsOnly
, mkCargoDerivation
, nodePackages
, trunk
, wasm-bindgen-cli
}:

{ trunkExtraArgs ? ""
, trunkExtraBuildArgs ? ""
, trunkIndexPath ? "./index.html"
, ...
}@origArgs:
let
  args = builtins.removeAttrs origArgs [
    "installPhase"
    "installPhaseCommand"
    "trunkExtraArgs"
    "trunkExtraBuildArgs"
    "trunkIndexPath"
  ];
in
mkCargoDerivation (args // {
  pnameSuffix = "-trunk";

  cargoArtifacts = args.cargoArtifacts or (buildDepsOnly (args // {
    CARGO_BUILD_TARGET = args.CARGO_BUILD_TARGET or "wasm32-unknown-unknown";
    installCargoArtifactsMode = args.installCargoArtifactsMode or "use-zstd";
    doCheck = args.doCheck or false;
  }));

  # Force trunk to not download dependencies, but set the version with
  # whatever tools actually make it into the builder's PATH
  preConfigure = ''
    echo configuring trunk tools
    export TRUNK_TOOLS_SASS=$(sass --version | cut -d' ' -f1)
    export TRUNK_TOOLS_WASM_BINDGEN=$(wasm-bindgen --version | cut -d' ' -f2)
    export TRUNK_TOOLS_WASM_OPT=$(wasm-opt --version | cut -d' ' -f3)

    echo "TRUNK_TOOLS_SASS=''${TRUNK_TOOLS_SASS}"
    echo "TRUNK_TOOLS_WASM_BINDGEN=''${TRUNK_TOOLS_WASM_BINDGEN}"
    echo "TRUNK_TOOLS_WASM_OPT=''${TRUNK_TOOLS_WASM_OPT}"
  '';

  buildPhaseCargoCommand = args.buildPhaseCommand or ''
    local profileArgs=""
    if [[ "$CARGO_PROFILE" == "release" ]]; then
      profileArgs="--release"
    fi

    trunk ${trunkExtraArgs} build $profileArgs ${trunkExtraBuildArgs} "${trunkIndexPath}"
  '';

  installPhase = args.installPhase or ''
    cp -r "$(dirname "${trunkIndexPath}")/dist" $out
  '';

  nativeBuildInputs = (args.nativeBuildInputs or [ ]) ++ [
    binaryen
    # dart-sass compiled to javascript
    # TODO: replace with a native version when it comes to nixpkgs
    nodePackages.sass
    trunk
    wasm-bindgen-cli
  ];
})
