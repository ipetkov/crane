{ cargoBuild
, clippy
, buildDepsOnly
}:

{ cargoArtifacts
, cargoClippyExtraArgs ? ""
, cargoExtraArgs ? ""
, ...
}@origArgs:
let
  args = builtins.removeAttrs origArgs [ "cargoClippyExtraArgs" ];
in
cargoBuild (args // {
  inherit cargoArtifacts;
  pnameSuffix = "-clippy";

  cargoBuildCommand = "cargo clippy --workspace --release --all-targets";
  cargoExtraArgs = "${cargoExtraArgs} ${cargoClippyExtraArgs}";

  nativeBuildInputs = (args.nativeBuildInputs or [ ]) ++ [ clippy ];

  doCheck = false; # We don't need to run tests to benefit from `cargo check`

  # The existence of the build completing without error is enough to ensure
  # the checks have passed, so we do not strictly need to install the cargo artifacts.
  # However, we allow the caller to retain them if needed.
  doCopyTargetToOutput = args.doCopyTargetToOutput or false;
})
