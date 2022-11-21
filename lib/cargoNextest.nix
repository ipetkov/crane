{ cargo-nextest
, lib
, mkCargoDerivation
, runCommand
}:

{ cargoArtifacts
, cargoExtraArgs ? ""
, cargoNextestExtraArgs ? ""
, doInstallCargoArtifacts ? true
, partitions ? 1
, partitionType ? "count"
, ...
}@origArgs:
let
  args = builtins.removeAttrs origArgs [
    "cargoExtraArgs"
    "cargoNextestExtraArgs"
    "partitions"
    "partitionType"
  ];

  mkUpdatedArgs = { cmd ? "run", extraSuffix ? "", moreArgs ? "" }: args // {
    inherit cargoArtifacts;
    pnameSuffix = "-nextest${extraSuffix}";
    doCheck = args.doCheck or true;

    buildPhaseCargoCommand = args.buildPhaseCargoCommand or ''
      mkdir -p $out
      cargo nextest --version
    '';

    checkPhaseCargoCommand = "cargo nextest ${cmd} $" + "{CARGO_PROFILE:+--cargo-profile $CARGO_PROFILE} ${cargoExtraArgs} ${cargoNextestExtraArgs} ${moreArgs}";

    nativeBuildInputs = (args.nativeBuildInputs or [ ]) ++ [ cargo-nextest ];
  };
in
if partitions < 1 then
  throw "paritions must be at least 1 or greater"
else if partitions == 1 then # Simple case do everything in one derivation
  mkCargoDerivation (mkUpdatedArgs { })
else # First build the tests in one derivation, then run each partition in another
  let
    mkArchiveArgs = root: "--archive-format tar-zst --archive-file ${root}/archive.tar.zst";
    archive = mkCargoDerivation (mkUpdatedArgs {
      cmd = "archive";
      moreArgs = mkArchiveArgs "$out";
    });
    mkPartition = nInt:
      let
        n = toString (nInt + 1);
      in
      mkCargoDerivation ((mkUpdatedArgs {
        extraSuffix = "-p${toString n}";
        moreArgs = "${mkArchiveArgs archive} --partition ${partitionType}:${n}/${toString partitions}";
      }) // {
        # Everything we need is already in the archive
        cargoArtifacts = null;
        cargoVendorDir = null;
        doInstallCargoArtifacts = false;

        # Nextest does not like extra args when running with an archive
        CARGO_PROFILE = "";
      });
  in
  # Allow for retaining the artifacts from the `archive` derivation
    # if callers want to chain other derivations after it. We provide
    # the actual `partition*` derivations as inputs to ensure they are run.
  runCommand "cargo-nextest-tests"
  {
    inherit doInstallCargoArtifacts;
    buildInputs = lib.genList mkPartition partitions;
  } ''
    if [ "1" = "''${doInstallCargoArtifacts-}" ]; then
      cp --recursive ${archive} $out/
    else
      mkdir -p $out
    fi
  ''
