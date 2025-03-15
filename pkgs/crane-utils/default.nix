{ lib
, rustPlatform
}:

rustPlatform.buildRustPackage {
  pname = "crane-utils";
  version = "0.0.1";

  src = lib.sourceFilesBySuffices ./. [ ".rs" ".toml" ".lock" ];
  cargoLock.lockFile = ./Cargo.lock;
}
