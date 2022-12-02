{ cargoNextest
, linkFarmFromDrvs
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
in
linkFarmFromDrvs "nextestTests" [
  nextestSimple
  nextestPartitionsCount
  nextestPartitionsHash
]
