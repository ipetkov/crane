{ lib
, mkMyPkgs
, newScope
}:

lib.makeScope newScope (self:
let
  inherit (self) callPackage;
in
(mkMyPkgs callPackage) // {
  appendCrateRegistries = input: self.overrideScope' (final: prev: {
    crateRegistries = prev.crateRegistries // (lib.foldl (a: b: a // b) { } input);
  });

  buildDepsOnly = callPackage ./buildDepsOnly.nix { };
  buildPackage = callPackage ./buildPackage.nix { };
  cargoAudit = callPackage ./cargoAudit.nix { };
  cargoBuild = callPackage ./cargoBuild.nix { };
  cargoClippy = callPackage ./cargoClippy.nix { };
  cargoDoc = callPackage ./cargoDoc.nix { };
  cargoFmt = callPackage ./cargoFmt.nix { };
  cargoNextest = callPackage ./cargoNextest.nix { };
  cargoTarpaulin = callPackage ./cargoTarpaulin.nix { };
  cleanCargoSource = callPackage ./cleanCargoSource.nix { };
  cleanCargoToml = callPackage ./cleanCargoToml.nix { };
  crateNameFromCargoToml = callPackage ./crateNameFromCargoToml.nix { };

  crateRegistries = self.registryFromDownloadUrl {
    dl = "https://crates.io/api/v1/crates";
    indexUrl = "https://github.com/rust-lang/crates.io-index";
  };

  downloadCargoPackage = callPackage ./downloadCargoPackage.nix { };
  downloadCargoPackageFromGit = callPackage ./downloadCargoPackageFromGit.nix { };
  findCargoFiles = callPackage ./findCargoFiles.nix { };
  filterCargoSources = callPackage ./filterCargoSources.nix { };
  mkCargoDerivation = callPackage ./mkCargoDerivation.nix { };
  mkDummySrc = callPackage ./mkDummySrc.nix { };

  overrideToolchain = toolchain: self.overrideScope' (final: prev: {
    cargo = toolchain;
    clippy = toolchain;
    rustc = toolchain;
    rustfmt = toolchain;
  });

  registryFromDownloadUrl = callPackage ./registryFromDownloadUrl.nix { };
  registryFromGitIndex = callPackage ./registryFromGitIndex.nix { };
  urlForCargoPackage = callPackage ./urlForCargoPackage.nix { };
  vendorCargoDeps = callPackage ./vendorCargoDeps.nix { };
  vendorCargoRegistries = callPackage ./vendorCargoRegistries.nix { };
  vendorGitDeps = callPackage ./vendorGitDeps.nix { };
  writeTOML = callPackage ./writeTOML.nix { };
})
