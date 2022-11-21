{ cargo-nextest
, cargoNextest
, lib
, runCommand
}:

let
  # cargo-nextest version in the stable-22.05 branch is too old
  nextestSupportsArchives = lib.versionAtLeast
    cargo-nextest.version
    "0.9.15";

  nextestSimple = cargoNextest {
    src = ./simple;
    pname = "nextest-simple";
    cargoArtifacts = null;
  };

  nextestPartitionsCount = cargoNextest {
    src = ./simple;
    pname = "nextest-partitions-count";
    partitions = 4;
    partitionType = "count";
    cargoArtifacts = null;
  };

  nextestPartitionsHash = cargoNextest {
    src = ./simple;
    pname = "nextest-partitions-hash";
    partitions = 4;
    partitionType = "hash";
    cargoArtifacts = null;
  };
in
runCommand "nextestTests"
{
  buildInputs = [ nextestSimple ] ++ (lib.optionals nextestSupportsArchives [
    nextestPartitionsCount
    nextestPartitionsHash
  ]);
} ''
  mkdir -p $out
''
