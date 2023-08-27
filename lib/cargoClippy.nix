{ clippy
, mkCargoDerivation
}:

{ cargoArtifacts
, cargoClippyExtraArgs ? "--all-targets"
, cargoExtraArgs ? "--locked"
, ...
}@origArgs:
let
  args = builtins.removeAttrs origArgs [
    "cargoClippyExtraArgs"
    "cargoExtraArgs"
  ];
in
mkCargoDerivation (args // {
  inherit cargoArtifacts;
  pnameSuffix = "-clippy";

  buildPhaseCargoCommand = "cargoWithProfile clippy ${cargoExtraArgs} ${cargoClippyExtraArgs}";

  nativeBuildInputs = (args.nativeBuildInputs or [ ]) ++ [ clippy ];
})
