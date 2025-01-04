{ cargoNextest
, lib
, linkFarmFromDrvs
}:

let
  nextestSimple = withLlvmCov: cargoNextest {
    inherit withLlvmCov;
    src = ./simple;
    pname = "nextest-simple${lib.optionalString withLlvmCov "-llvm-cov"}";
    cargoArtifacts = null;
  };

  nextestPartitionsCount = withLlvmCov: cargoNextest {
    inherit withLlvmCov;
    src = ./simple;
    pname = "nextest-partitions-count${lib.optionalString withLlvmCov "-llvm-cov"}";
    partitions = 4;
    partitionType = "count";
    cargoArtifacts = null;
  };

  nextestPartitionsHash = withLlvmCov: cargoNextest {
    inherit withLlvmCov;
    src = ./simple;
    pname = "nextest-partitions-hash${lib.optionalString withLlvmCov "-llvm-cov"}";
    partitions = 4;
    partitionType = "hash";
    cargoArtifacts = null;
    cargoNextestPartitionsExtraArgs = "--no-tests=pass";
  };

  nextestProcMacro = withLlvmCov: cargoNextest {
    inherit withLlvmCov;
    src = ./proc-macro;
    pname = "nextest-proc-macro${lib.optionalString withLlvmCov "-llvm-cov"}";
    cargoArtifacts = null;
    cargoNextestExtraArgs = "--no-tests=pass";
  };
in
linkFarmFromDrvs "nextestTests" [
  (nextestSimple false)
  (nextestSimple true)
  (nextestPartitionsCount false)
  (nextestPartitionsCount true)
  (nextestPartitionsHash false)
  #(nextestPartitionsHash true) # not yet supported
  (nextestProcMacro false)
  (nextestProcMacro true)
]
