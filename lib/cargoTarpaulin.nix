{ mkCargoDerivation
, cargo-tarpaulin
}:

{ cargoExtraArgs ? ""
, cargoTarpaulinExtraArgs ? "--skip-clean --out Xml --output-dir $out"
, ...
}@origArgs:
let
  args = builtins.removeAttrs origArgs [
    "cargoExtraArgs"
    "cargoTarpaulinExtraArgs"
  ];
in
mkCargoDerivation (args // {
  buildPhaseCargoCommand = "cargoWithProfile tarpaulin ${cargoExtraArgs} ${cargoTarpaulinExtraArgs}";

  pnameSuffix = "-tarpaulin";

  nativeBuildInputs = (args.nativeBuildInputs or [ ]) ++ [ cargo-tarpaulin ];
})
