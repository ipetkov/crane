{ mkCargoDerivation
, cargo-llvm-cov
}:

{ cargoExtraArgs ? ""
, cargoLlvmCovCommand ? "test"
, cargoLlvmCovExtraArgs ? "--lcov --output-path $out"
, CARGO_PROFILE ? ""
, ...
}@origArgs:

let
  args = builtins.removeAttrs origArgs [
    "cargoExtraArgs"
    "cargoLlvmCovCommand"
    "cargoLlvmCovExtraArgs"
  ];
in

mkCargoDerivation (args // {
  inherit CARGO_PROFILE;

  pnameSuffix = "-llvm-cov";

  nativeBuildInputs = (args.nativeBuildInputs or [ ]) ++ [ cargo-llvm-cov ];

  doInstallCargoArtifacts = false;

  # `cargoWithProfile` injects the `--profile` flag before the subcommand,
  # which breaks cargo-llvm-cov, so we have to use `cargo` here
  buildPhaseCargoCommand = ''
    cargo llvm-cov "${cargoLlvmCovCommand}" \
      ''${CARGO_PROFILE:+--profile $CARGO_PROFILE} \
      ${cargoExtraArgs} ${cargoLlvmCovExtraArgs}
  '';

  installPhaseCommand = "";
})
