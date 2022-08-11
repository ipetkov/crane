{ cargoBuild
, clippy
}:

{ cargoArtifacts
, cargoClippyExtraArgs ? "--all-targets"
, cargoExtraArgs ? ""
, ...
}@origArgs:
let
  args = builtins.removeAttrs origArgs [ "cargoClippyExtraArgs" ];
in
cargoBuild (args // {
  inherit cargoArtifacts;
  pnameSuffix = "-clippy";

  cargoBuildCommand = "cargoWithProfile clippy";
  cargoExtraArgs = "${cargoExtraArgs} ${cargoClippyExtraArgs}";

  nativeBuildInputs = (args.nativeBuildInputs or [ ]) ++ [ clippy ];

  doCheck = false; # We don't need to run tests to benefit from `cargo clippy`
})
