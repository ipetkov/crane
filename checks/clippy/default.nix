{ buildDepsOnly
, cargoClippy
, crateNameFromCargoToml
, linkFarmFromDrvs
, mkDummySrc
}:

let
  src = ./clippytest;
  cargoArtifacts = buildDepsOnly {
    inherit src;
  };
in
linkFarmFromDrvs "clippy-tests" (builtins.attrValues {
  clippytest = cargoClippy {
    inherit cargoArtifacts src;
  };

  dummySrc = cargoClippy ((crateNameFromCargoToml { inherit src; }) // {
    cargoArtifacts = null;
    src = mkDummySrc {
      inherit src;
    };
  });

  checkWarnings = cargoClippy {
    inherit cargoArtifacts src;
    pname = "checkWarnings";

    cargoClippyExtraArgs = "--all-targets 2>clippy.log";
    installPhaseCommand = ''
      grep 'warning: use of `println!`' <clippy.log
      mkdir -p $out
    '';
  };

  denyWarnings = cargoClippy {
    inherit cargoArtifacts src;
    pname = "denyWarnings";

    cargoClippyExtraArgs = ''
      --all-targets -- --deny warnings 2>clippy.log || [ "0" != "$?" ]
    '';
    installPhaseCommand = ''
      grep 'error: use of `println!`' <clippy.log
      mkdir -p $out
    '';
  };
})
