{ buildDepsOnly
, buildPackage
, cargoClippy
, cargoFmt
, cleanCargoSource
}:

let
  src = cleanCargoSource ./.;

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
