{ mkCargoDerivation
, buildDepsOnly
, trunk
, wasm-bindgen-cli
, binaryen
, nodePackages
}:

{ cargoArtifacts ? null
, trunkIndexPath ? "./index.html"
, trunkExtraArgs ? ""
, trunkExtraBuildArgs ? ""
, ...
}@origArgs:
let
  args = builtins.removeAttrs origArgs [
    "trunkIndexPath"
    "trunkExtraArgs"
    "trunkExtraBuildArgs"
  ];

  depsArgs = args // {
    installCargoArtifactsMode = args.installCargoArtifactsMode or "use-zstd";
    doCheck = args.doCheck or false;
  };

  generatedCargoArtifacts = buildDepsOnly (
    removeAttrs depsArgs [ "installPhase" "installPhaseCommand" ]
  );
in
mkCargoDerivation (args // {
  pnameSuffix = "-trunk";

  cargoArtifacts = (args.cargoArtifacts or generatedCargoArtifacts).overrideAttrs (old: {
    CARGO_BUILD_TARGET = old.CARGO_BUILD_TARGET or "wasm32-unknown-unknown";
  });

  # Force trunk to not download dependencies
  TRUNK_TOOLS_SASS = nodePackages.sass.version;
  TRUNK_TOOLS_WASM_BINDGEN = wasm-bindgen-cli.version;
  TRUNK_TOOLS_WASM_OPT = "version_${binaryen.version}";

  buildPhaseCargoCommand = ''
    (
      set -x
      trunk --version
      wasm-bindgen --version
      wasm-opt --version
      sass --version
    )

    trunk ${trunkExtraArgs} build --release ${trunkExtraBuildArgs} "${trunkIndexPath}"
  '';

  installPhase = ''
    cp -r "$(dirname "${trunkIndexPath}")/dist" $out
  '';

  buildInputs = (args.buildInputs or [ ]) ++ [
    trunk
    wasm-bindgen-cli
    binaryen
    # dart-sass compiled to javascript
    # TODO: replace with a native version when it comes to nixpkgs
    nodePackages.sass
  ];
})
