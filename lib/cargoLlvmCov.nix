{ mkCargoDerivation
, cargo-llvm-cov
}:

{ cargoExtraArgs ? "--locked"
, cargoLlvmCovCommand ? "test"
, cargoLlvmCovExtraArgs ? "--lcov --output-path $out"
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
  pnameSuffix = "-llvm-cov";

  nativeBuildInputs = (args.nativeBuildInputs or [ ]) ++ [ cargo-llvm-cov ];

  doInstallCargoArtifacts = false;

  buildPhaseCargoCommand = ''
    cargoWithProfile llvm-cov "${cargoLlvmCovCommand}" ${cargoExtraArgs} ${cargoLlvmCovExtraArgs}
  '';

  installPhaseCommand = "";
})
