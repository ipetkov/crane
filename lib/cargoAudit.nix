{ cargoBuild
, cargo-audit
,
}: { cargoArtifacts
   , cargoAuditExtraArgs ? ""
   , cargoExtraArgs ? ""
   , advisory-db
   , ...
   } @ origArgs:
let
  args = builtins.removeAttrs origArgs [ "cargoAuditExtraArgs" ];
in
cargoBuild (args
  // {
  inherit cargoArtifacts;
  cargoBuildCommand = "cargo audit -n -d ${advisory-db}";
  cargoExtraArgs = "${cargoExtraArgs} ${cargoAuditExtraArgs}";

  doCheck = false; # We don't need to run tests to benefit from `cargo audit`
  pnameSuffix = "-audit";

  nativeBuildInputs = (args.nativeBuildInputs or [ ]) ++ [ cargo-audit ];
})
