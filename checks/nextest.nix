{ cargoNextest
, runCommand
}:

let
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

  nextestProcMacro = cargoNextest {
    src = ./proc-macro;
    pname = "nextest-proc-macro";
    cargoArtifacts = null;
  };
in
runCommand "nextestTests"
{
  buildInputs = [
    nextestSimple
    nextestPartitionsCount
    nextestPartitionsHash
    nextestProcMacro
  ];
} ''
  mkdir -p $out
''
