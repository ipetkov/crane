{ mkCargoDerivation
}:

{ cargoDocExtraArgs ? "--no-deps"
, cargoExtraArgs ? "--locked"
, preInstall ? ""
, ...
}@origArgs:
let
  args = (builtins.removeAttrs origArgs [
    "cargoDocExtraArgs"
    "cargoExtraArgs"
    "preInstall"
  ]);
in
mkCargoDerivation (args // {
  pnameSuffix = "-doc";

  buildPhaseCargoCommand = "cargoWithProfile doc ${cargoExtraArgs} ${cargoDocExtraArgs}";

  preInstall = preInstall + ''
    rm -rf target/release
  '';
})
