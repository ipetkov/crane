{ fromTOML
, lib
, mkMyPkgs
, newScope
}:

lib.makeScope newScope (self:
  let
    inherit (self) callPackage;
  in
  (mkMyPkgs callPackage) // {
    inherit fromTOML;

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
    downloadCargoPackageFromGit = callPackage ./downloadCargoPackageFromGit.nix { };
    findCargoFiles = callPackage ./findCargoFiles.nix { };
    mkCargoDerivation = callPackage ./mkCargoDerivation.nix { };
    mkDummySrc = callPackage ./mkDummySrc.nix { };
    registryFromDownloadUrl = callPackage ./registryFromDownloadUrl.nix { };
    registryFromGitIndex = callPackage ./registryFromGitIndex.nix { };
    urlForCargoPackage = callPackage ./urlForCargoPackage.nix { };
    vendorCargoDeps = callPackage ./vendorCargoDeps.nix { };
    vendorCargoRegistries = callPackage ./vendorCargoRegistries.nix { };
    vendorGitDeps = callPackage ./vendorGitDeps.nix { };
    writeTOML = callPackage ./writeTOML.nix { };
  })
