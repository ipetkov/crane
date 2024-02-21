{ lib
, rustPlatform
}:

rustPlatform.buildRustPackage {
  pname = "crane-utils";
  version = "0.0.1";

  src = lib.sourceFilesBySuffices ./. [ ".rs" ".toml" ".lock" ];

  cargoHash = "sha256-b/l0GV2QCHntdMFFkAtsPjnVMAFUC++2J4VnIyavf6w=";
}
