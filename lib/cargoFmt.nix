{ cargoBuild
, rustfmt
}:

{ cargoExtraArgs ? ""
, rustFmtExtraArgs ? ""
, ...
}@origArgs:
let
  args = builtins.removeAttrs origArgs [ "rustFmtExtraArgs" ];
in
cargoBuild (args // {
  cargoArtifacts = null;
  cargoVendorDir = null;
  doCheck = false;
  doRemapSourcePathPrefix = false;
  pnameSuffix = "-fmt";

  cargoBuildCommand = "cargo fmt";
  cargoExtraArgs = "${cargoExtraArgs} -- --check ${rustFmtExtraArgs}";

  nativeBuildInputs = (args.nativeBuildInputs or [ ]) ++ [ rustfmt ];

  preInstallPhases = [ "ensureTargetDir" ] ++ (args.preInstallPhases or [ ]);
  ensureTargetDir = ''
    mkdir -p ''${CARGO_TARGET_DIR:-target}
  '';
})
