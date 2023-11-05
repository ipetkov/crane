{ cargo-deny
, mkCargoDerivation
}:

{ cargoDenyExtraArgs ? ""
, cargoDenyChecks ? "bans licenses sources"
, cargoExtraArgs ? ""
, ...
}@origArgs:
let
  args = builtins.removeAttrs origArgs [
    "cargoDenyExtraArgs"
    "cargoExtraArgs"
  ];
in
mkCargoDerivation (args // {
  buildPhaseCargoCommand = ''
    cargo --offline ${cargoExtraArgs} \
      deny ${cargoDenyExtraArgs} check ${cargoDenyChecks}
  '';

  cargoArtifacts = null;
  doInstallCargoArtifacts = false;
  pnameSuffix = "-deny";

  nativeBuildInputs = (args.nativeBuildInputs or [ ]) ++ [ cargo-deny ];
})
