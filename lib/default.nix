{ fromTOML
, lib
, myPkgs
, newScope
, toTOML
}:

lib.makeScope newScope (self:
  let
    callPackage = self.newScope myPkgs;
  in
  {
    inherit fromTOML toTOML;

    appendCrateRegistries = input: self.overrideScope' (final: prev: {
      crateRegistries = prev.crateRegistries // (lib.foldl (a: b: a // b) { } input);
    });

    buildDepsOnly = callPackage ./buildDepsOnly.nix { };
    buildPackage = callPackage ./buildPackage.nix { };
    cargoBuild = callPackage ./cargoBuild.nix { };
    cargoClippy = callPackage ./cargoClippy.nix { };
    cargoFmt = callPackage ./cargoFmt.nix { };
    cargoTarpaulin = callPackage ./cargoTarpaulin.nix { };
    cleanCargoToml = callPackage ./cleanCargoToml.nix { };
    crateNameFromCargoToml = callPackage ./crateNameFromCargoToml.nix { };

    crateRegistries = self.registryFromDownloadUrl {
      dl = "https://crates.io/api/v1/crates";
      indexUrl = "https://github.com/rust-lang/crates.io-index";
    };

    downloadCargoPackage = callPackage ./downloadCargoPackage.nix { };
    findCargoFiles = callPackage ./findCargoFiles.nix { };
    mkCargoDerivation = callPackage ./mkCargoDerivation.nix { };
    mkDummySrc = callPackage ./mkDummySrc.nix { };
    registryFromDownloadUrl = callPackage ./registryFromDownloadUrl.nix { };
    registryFromGitIndex = callPackage ./registryFromGitIndex.nix { };
    urlForCargoPackage = callPackage ./urlForCargoPackage.nix { };
    vendorCargoDeps = callPackage ./vendorCargoDeps.nix { };
    vendorCargoRegistries = callPackage ./vendorCargoRegistries.nix { };
    writeTOML = callPackage ./writeTOML.nix { };
  })
