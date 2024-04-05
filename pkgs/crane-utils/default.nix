{ lib
, rustPlatform
}:

rustPlatform.buildRustPackage {
  pname = "crane-utils";
  version = "0.0.1";

  src = lib.sourceFilesBySuffices ./. [ ".rs" ".toml" ".lock" ];

  cargoSha256 = "sha256-hOCx+2IPAaEOeCmS4BzP3yXDECI39VwoDtGNqhtIspo=";
}
