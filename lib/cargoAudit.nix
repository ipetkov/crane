{ cargoBuild
, audit
}:

{ cargoArtifacts
, cargoAuditExtraArgs ? ""
, cargoExtraArgs ? ""
, ...
}@origArgs:
let
  args = builtins.removeAttrs origArgs [ "cargoAuditExtraArgs" ];
in
cargoBuild (args // {
  inherit cargoArtifacts;
  pnameSuffix = "-audit";

  cargoBuildCommand = "cargo audit";
  cargoExtraArgs = "${cargoExtraArgs} ${cargoAuditExtraArgs}";

  nativeBuildInputs = (args.nativeBuildInputs or [ ]) ++ [ audit ];

  doCheck = false; # We don't need to run tests to benefit from `cargo audit`
})
