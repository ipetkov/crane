{ buildDepsOnly
, cargoBuild
, cargo-tarpaulin
}:

{ cargoExtraArgs ? ""
, cargoTarpaulinExtraArgs ? "--skip-clean --out Xml --output-dir $out"
, ...
}@origArgs:
let
  args = builtins.removeAttrs origArgs [ "cargoTarpaulinExtraArgs" ];
in
cargoBuild (args // {
  cargoArtifacts = args.cargoArtifacts or (buildDepsOnly args);
  cargoBuildCommand = "cargo tarpaulin";
  cargoExtraArgs = "${cargoExtraArgs} ${cargoTarpaulinExtraArgs}";

  doCheck = false;
  pnameSuffix = "-tarpaulin";

  nativeBuildInputs = (args.nativeBuildInputs or [ ]) ++ [ cargo-tarpaulin ];
})
