{ lib
, rustPlatform
}:

rustPlatform.buildRustPackage {
  pname = "crane-utils";
  version = "0.0.1";

  src = lib.sourceFilesBySuffices ./. [ ".rs" ".toml" ".lock" ];

  cargoHash = "sha256-yVe6BIUuZygz44GiPRWAjMCU9IbglyrS2RAuLcP+3Ls=";
}
