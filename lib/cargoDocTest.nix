{ mkCargoDerivation
}:

{ cargoArtifacts
, cargoExtraArgs ? "--locked"
, cargoTestExtraArgs ? ""
, ...
}@origArgs:
let
  args = (builtins.removeAttrs origArgs [
    "cargoExtraArgs"
    "cargoTestExtraArgs"
  ]);
in
mkCargoDerivation (args // {
  inherit cargoArtifacts;
  doCheck = args.doCheck or true;

  pnameSuffix = "-doctest";
  buildPhaseCargoCommand = "";
  checkPhaseCargoCommand = "cargoWithProfile test --doc ${cargoExtraArgs} ${cargoTestExtraArgs}";
})
