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

  pnameSuffix = "-test";
  buildPhaseCargoCommand = "";
  checkPhaseCargoCommand = "cargoWithProfile test ${cargoExtraArgs} ${cargoTestExtraArgs}";
})
