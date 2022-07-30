{ cargoBuild
, cargo-audit
,
}: { cargoAuditExtraArgs ? ""
   , cargoExtraArgs ? ""
   , advisory-db
   , ...
   } @ origArgs:
let
  args = builtins.removeAttrs origArgs [ "cargoAuditExtraArgs" ];
in
cargoBuild (args // {
  cargoArtifacts = null;
  cargoBuildCommand = "cargo audit -n -d ${advisory-db}";
  cargoExtraArgs = "${cargoExtraArgs} ${cargoAuditExtraArgs}";

  doCheck = false; # We don't need to run tests to benefit from `cargo audit`
  doInstallCargoArtifacts = false; # We don't expect to/need to install artifacts
  pnameSuffix = "-audit";

  nativeBuildInputs = (args.nativeBuildInputs or [ ]) ++ [ cargo-audit ];
})
