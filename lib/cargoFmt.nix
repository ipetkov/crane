{ mkCargoDerivation
, rustfmt
}:

{ cargoExtraArgs ? ""
, rustFmtExtraArgs ? ""
, ...
}@origArgs:
let
  args = builtins.removeAttrs origArgs [
    "cargoExtraArgs"
    "rustFmtExtraArgs"
  ];
in
mkCargoDerivation (args // {
  cargoArtifacts = null;
  cargoVendorDir = null;
  pnameSuffix = "-fmt";

  buildPhaseCargoCommand = "cargo fmt ${cargoExtraArgs} -- --check ${rustFmtExtraArgs}";

  nativeBuildInputs = (args.nativeBuildInputs or [ ]) ++ [ rustfmt ];

  preInstallPhases = [ "ensureTargetDir" ] ++ (args.preInstallPhases or [ ]);
  ensureTargetDir = ''
    mkdir -p ''${CARGO_TARGET_DIR:-target}
  '';
})
