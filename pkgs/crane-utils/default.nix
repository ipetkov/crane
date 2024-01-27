{ buildDepsOnly
, cargoClippy
, cargoFmt
, cleanCargoSource
, crateNameFromCargoToml
, path
, rustPlatform
}:

let
  src = cleanCargoSource (path ./.);

  cargoArtifacts = buildDepsOnly {
    inherit src;
  };
in
rustPlatform.buildRustPackage {
  inherit src;
  inherit (crateNameFromCargoToml { inherit src; }) pname version;

  cargoSha256 = "sha256-oE67gg4+csvsGvMn2YyRnmZCqSodbFCLvzQi7kgsnfs=";

  passthru = {
    checks = {
      clippy = cargoClippy {
        inherit cargoArtifacts src;
        cargoClippyExtraArgs = "--all-targets -- --deny warnings";
      };

      fmt = cargoFmt {
        inherit src;
      };
    };
  };
}
