{ lib
, rustPlatform
}:

rustPlatform.buildRustPackage {
  pname = "crane-utils";
  version = "0.0.1";

  src = lib.sourceFilesBySuffices ./. [ ".rs" ".toml" ".lock" ];

  cargoSha256 = "sha256-sRVk7OrdIYaNBU6gA1etLTVWQvS+HW5DwJaa2xbNqiA=";
}
