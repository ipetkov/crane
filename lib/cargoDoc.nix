{ mkCargoDerivation
}:

{ cargoDocExtraArgs ? "--no-deps"
, cargoExtraArgs ? ""
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
})
