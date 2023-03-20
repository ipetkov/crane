{ buildDepsOnly
, buildPackage
, cargoClippy
, cargoFmt
, cleanCargoSource
, path
}:

let
  src = cleanCargoSource (path ./.);

  cargoArtifacts = buildDepsOnly {
    inherit src;
  };
in
buildPackage {
  inherit cargoArtifacts src;

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
