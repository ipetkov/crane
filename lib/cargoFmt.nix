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
  doInstallCargoArtifacts = false;
  doRemapSourcePathPrefix = false;
  pnameSuffix = "-fmt";

  cargoBuildCommand = "cargo fmt";
  cargoExtraArgs = "${cargoExtraArgs} -- --check ${rustFmtExtraArgs}";

  nativeBuildInputs = (args.nativeBuildInputs or [ ]) ++ [ rustfmt ];
})
