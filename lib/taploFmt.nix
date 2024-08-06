{ taplo
, mkCargoDerivation
}:

{ taploExtraArgs ? ""
, ...
}@origArgs:
let
  args = builtins.removeAttrs origArgs [ "taploExtraArgs" ];
in
mkCargoDerivation (args // {
  cargoArtifacts = null;
  cargoVendorDir = null;
  pnameSuffix = "-tomlfmt";

  buildPhaseCargoCommand = "taplo fmt --check ${taploExtraArgs}";

  nativeBuildInputs = (args.nativeBuildInputs or [ ]) ++ [ taplo ];

  preInstallPhases = [ "ensureTargetDir" ] ++ (args.preInstallPhases or [ ]);
  ensureTargetDir = ''
    mkdir -p ''${CARGO_TARGET_DIR:-target}
  '';
})
