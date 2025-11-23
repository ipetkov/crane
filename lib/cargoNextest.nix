{
  cargo-llvm-cov,
  cargo-nextest,
  lib,
  mkCargoDerivation,
  runCommand,
}:

{
  cargoArtifacts,
  cargoExtraArgs ? "",
  cargoLlvmCovExtraArgs ? "--lcov --output-path $out/coverage",
  cargoNextestExtraArgs ? "",
  cargoNextestPartitionsExtraArgs ? "",
  doInstallCargoArtifacts ? true,
  partitions ? 1,
  partitionType ? "count",
  withLlvmCov ? false,
  ...
}@origArgs:
let
  args = builtins.removeAttrs origArgs [
    "cargoExtraArgs"
    "cargoLlvmCovExtraArgs"
    "cargoNextestExtraArgs"
    "cargoNextestPartitionsExtraArgs"
    "partitions"
    "partitionType"
    "withLlvmCov"
  ];

  mkUpdatedArgs =
    {
      cmd ? "run",
      extraSuffix ? "",
      moreArgs ? "",
      withLlvmCov,
    }:
    args
    // {
      inherit cargoArtifacts;
      pnameSuffix = "-nextest${extraSuffix}";
      doCheck = args.doCheck or true;

      buildPhaseCargoCommand =
        args.buildPhaseCargoCommand or ''
          mkdir -p $out
          ${lib.optionalString withLlvmCov "cargo llvm-cov --version"}
          cargo nextest --version
        '';

      checkPhaseCargoCommand = ''
        ${
          if withLlvmCov then "cargo llvm-cov nextest ${cargoLlvmCovExtraArgs}" else "cargo nextest ${cmd}"
        } \
        ''${CARGO_PROFILE:+--cargo-profile $CARGO_PROFILE} \
        ${cargoExtraArgs} ${cargoNextestExtraArgs} ${moreArgs}
      '';

      nativeBuildInputs =
        (args.nativeBuildInputs or [ ])
        ++ [ cargo-nextest ]
        ++ lib.lists.optional withLlvmCov cargo-llvm-cov;

      # Load bearing prepend here, in case the caller sets `preConfigure = "no newline";`
      # we don't want to get a syntax error here (given how these are concatenated)
      preConfigure = ''
        if [[ -z "''${doCheck:-}" ]]; then
          echo '#####################################################'
          echo '##                                                 ##'
          echo '## doCheck is not set, nextest tests will not run! ##'
          echo '##                                                 ##'
          echo '#####################################################'
        fi
      ''
      + (args.preConfigure or "");
    };
in
if partitions < 1 then
  throw "paritions must be at least 1 or greater"
else if partitions == 1 then # Simple case do everything in one derivation
  mkCargoDerivation (mkUpdatedArgs {
    inherit withLlvmCov;
    moreArgs = cargoNextestPartitionsExtraArgs;
  })
# First build the tests in one derivation, then run each partition in another
else
  let
    mkArchiveArgs = root: "--archive-format tar-zst --archive-file ${root}/archive.tar.zst";
    archive = mkCargoDerivation (mkUpdatedArgs {
      cmd = "archive";
      moreArgs = mkArchiveArgs "$out";
      withLlvmCov =
        !(lib.asserts.assertMsg (!withLlvmCov) "withLLvmCov is not supported for partitioned runs");
    });
    mkPartition =
      nInt:
      let
        n = toString (nInt + 1);
      in
      mkCargoDerivation (
        (mkUpdatedArgs {
          inherit withLlvmCov;
          extraSuffix = "-p${toString n}";
          moreArgs = builtins.concatStringsSep " " (
            [
              "${mkArchiveArgs archive}"
              "--workspace-remap ."
              "--partition ${partitionType}:${n}/${toString partitions}"
            ]
            ++ lib.optional (cargoNextestPartitionsExtraArgs != "") cargoNextestPartitionsExtraArgs
          );
        })
        // {
          # Everything we need is already in the archive
          cargoArtifacts = null;
          cargoVendorDir = null;
          doInstallCargoArtifacts = false;

          # Nextest does not like extra args when running with an archive
          CARGO_PROFILE = "";
        }
      );
  in
  # Allow for retaining the artifacts from the `archive` derivation
  # if callers want to chain other derivations after it. We provide
  # the actual `partition*` derivations as inputs to ensure they are run.
  runCommand "cargo-nextest-tests"
    {
      inherit doInstallCargoArtifacts;
      buildInputs = lib.genList mkPartition partitions;
    }
    ''
      if [ "1" = "''${doInstallCargoArtifacts-}" ]; then
        cp --recursive ${archive} $out/
      else
        mkdir -p $out
      fi
    ''
