{ lib
, rustPlatform
}:

rustPlatform.buildRustPackage {
  pname = "crane-utils";
  version = "0.0.1";

  src = lib.sourceFilesBySuffices ./. [ ".rs" ".toml" ".lock" ];

  cargoHash = "sha256-TsfXO0cCR52xnNoxQbyH0kulth2XbT08M4dwSU4OM6M=";
}
