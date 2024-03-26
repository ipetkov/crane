{ lib
, rustPlatform
}:

rustPlatform.buildRustPackage {
  pname = "crane-utils";
  version = "0.0.1";

  src = lib.sourceFilesBySuffices ./. [ ".rs" ".toml" ".lock" ];

  cargoHash = "sha256-ZP8rFMuW6W+KSdU5OZviCcaZf3uAJZ8ie7ZNOhlZf4c=";
}
