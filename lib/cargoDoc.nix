{ mkCargoDerivation
}:

{ cargoDocExtraArgs ? "--no-deps"
, cargoExtraArgs ? "--locked"
, ...
}@origArgs:
let
  args = (builtins.removeAttrs origArgs [
    "cargoDocExtraArgs"
    "cargoExtraArgs"
    "docInstallRoot"
  ]);
in
mkCargoDerivation (args // {
  pnameSuffix = "-doc";

  buildPhaseCargoCommand = "cargoWithProfile doc ${cargoExtraArgs} ${cargoDocExtraArgs}";

  doInstallCargoArtifacts = args.doInstallCargoArtifacts or false;

  docInstallRoot = args.docInstallRoot or "";

  # NB: cargo always places docs at the root of the target directory
  # even when building in release mode, except when cross-compiling targets
  installPhaseCommand = ''
    if [ -z "''${docInstallRoot:-}" ]; then
      docInstallRoot="''${CARGO_TARGET_DIR:-target}/''${CARGO_BUILD_TARGET:-}/doc"
    fi

    mkdir -p $out/share
    mv "''${docInstallRoot}" $out/share
  '';
})
