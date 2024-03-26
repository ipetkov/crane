{ mkCargoDerivation
}:

{ cargoExtraArgs ? ""
, cargoBenchExtraArgs ? ""
, ...
}@origArgs:
let
  args = builtins.removeAttrs origArgs [
    "cargoExtraArgs"
    "cargoBenchExtraArgs"
  ];
in
mkCargoDerivation (args // {
  pnameSuffix = "-bench";

  buildPhaseCargoCommand = "cargoWithProfile bench ${cargoExtraArgs} ${cargoBenchExtraArgs}";
})
