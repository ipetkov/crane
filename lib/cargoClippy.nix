{ buildWithCargo
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
buildWithCargo (args // {
  inherit cargoArtifacts;

  buildPhaseCargoCommand = ''
    cargo clippy --workspace --release --all-targets ${cargoExtraArgs} ${cargoClippyExtraArgs}
  '';

  nativeBuildInputs = (args.nativeBuildInputs or [ ]) ++ [ clippy ];

  doCheck = false; # We don't need to run tests to benefit from `cargo check`
  doCopyTargetToOutput = true; # No point in building this if not for the cargo artifacts
})
