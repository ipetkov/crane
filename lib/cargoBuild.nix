{ mkCargoDerivation
}:

{ cargoArtifacts
, cargoExtraArgs ? "--locked"
, ...
}@origArgs:
let
  args = builtins.removeAttrs origArgs [
    "cargoExtraArgs"
  ];
in
mkCargoDerivation (args // {
  inherit cargoArtifacts;

  pnameSuffix = "-build";
  buildPhaseCargoCommand = "cargoWithProfile build ${cargoExtraArgs}";
})
