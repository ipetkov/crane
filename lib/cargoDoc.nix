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
  ]);
in
mkCargoDerivation (args // {
  pnameSuffix = "-doc";

  buildPhaseCargoCommand = "cargoWithProfile doc ${cargoExtraArgs} ${cargoDocExtraArgs}";

  doInstallCargoArtifacts = args.doInstallCargoArtifacts or false;

  docInstallRoot = args.docInstallRoot or "";

  # NB: cargo always places docs at the root of the target directory
  # even when building in release mode, except when cross-compiling targets.
  # However, even if CARGO_BUILD_TARGET is set but does not result in cross-compilation
  # cargo will still put the docs in the root of the target directory, so we need to take
  # that into account
  installPhaseCommand = ''
    if [ -z "''${docInstallRoot:-}" ]; then
      docInstallRoot="''${CARGO_TARGET_DIR:-target}/''${CARGO_BUILD_TARGET:-}/doc"

      if ! [ -d "''${docInstallRoot}" ]; then
        docInstallRoot="''${CARGO_TARGET_DIR:-target}/doc"
      fi
    fi

    mkdir -p $out/share
    mv "''${docInstallRoot}" $out/share
  '';
})
