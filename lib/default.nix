{ lib
, newScope
}:

lib.makeScope newScope (self:
let
  inherit (self) callPackage;

  internalCrateNameFromCargoToml = callPackage ./internalCrateNameFromCargoToml.nix { };
in
{
  appendCrateRegistries = input: self.overrideScope' (_final: prev: {
    crateRegistries = prev.crateRegistries // (lib.foldl (a: b: a // b) { } input);
  });

  buildDepsOnly = callPackage ./buildDepsOnly.nix { };
  buildPackage = callPackage ./buildPackage.nix { };
  buildTrunkPackage = callPackage ./buildTrunkPackage.nix { };
  cargoAudit = callPackage ./cargoAudit.nix { };
  cargoBuild = callPackage ./cargoBuild.nix { };
  cargoClippy = callPackage ./cargoClippy.nix { };
  cargoDoc = callPackage ./cargoDoc.nix { };
  cargoFmt = callPackage ./cargoFmt.nix { };
  cargoHelperFunctionsHook = callPackage ./setupHooks/cargoHelperFunctions.nix { };
  cargoLlvmCov = callPackage ./cargoLlvmCov.nix { };
  cargoNextest = callPackage ./cargoNextest.nix { };
  cargoTarpaulin = callPackage ./cargoTarpaulin.nix { };
  cargoTest = callPackage ./cargoTest.nix { };
  cleanCargoSource = callPackage ./cleanCargoSource.nix { };
  cleanCargoToml = callPackage ./cleanCargoToml.nix { };
  configureCargoCommonVarsHook = callPackage ./setupHooks/configureCargoCommonVars.nix { };
  configureCargoVendoredDepsHook = callPackage ./setupHooks/configureCargoVendoredDeps.nix { };
  craneUtils = callPackage ../pkgs/crane-utils { };

  crateNameFromCargoToml = callPackage ./crateNameFromCargoToml.nix {
    inherit internalCrateNameFromCargoToml;
  };

  crateRegistries = self.registryFromDownloadUrl {
    dl = "https://crates.io/api/v1/crates";
    indexUrl = "https://github.com/rust-lang/crates.io-index";
  };

  downloadCargoPackage = callPackage ./downloadCargoPackage.nix { };
  downloadCargoPackageFromGit = callPackage ./downloadCargoPackageFromGit.nix { };
  filterCargoSources = callPackage ./filterCargoSources.nix { };
  findCargoFiles = callPackage ./findCargoFiles.nix { };
  inheritCargoArtifactsHook = callPackage ./setupHooks/inheritCargoArtifacts.nix { };
  installCargoArtifactsHook = callPackage ./setupHooks/installCargoArtifacts.nix { };
  installFromCargoBuildLogHook = callPackage ./setupHooks/installFromCargoBuildLog.nix { };
  mkCargoDerivation = callPackage ./mkCargoDerivation.nix { };
  mkDummySrc = callPackage ./mkDummySrc.nix { };

  overrideToolchain = toolchain: self.overrideScope' (_final: _prev: {
    cargo = toolchain;
    clippy = toolchain;
    rustc = toolchain;
    rustfmt = toolchain;
  });

  path = callPackage ./path.nix {
    inherit internalCrateNameFromCargoToml;
  };

  registryFromDownloadUrl = callPackage ./registryFromDownloadUrl.nix { };
  registryFromGitIndex = callPackage ./registryFromGitIndex.nix { };
  removeReferencesToVendoredSourcesHook = callPackage ./setupHooks/removeReferencesToVendoredSources.nix { };
  urlForCargoPackage = callPackage ./urlForCargoPackage.nix { };
  vendorCargoDeps = callPackage ./vendorCargoDeps.nix { };
  vendorMultipleCargoDeps = callPackage ./vendorMultipleCargoDeps.nix { };
  vendorCargoRegistries = callPackage ./vendorCargoRegistries.nix { };
  vendorGitDeps = callPackage ./vendorGitDeps.nix { };
  writeTOML = callPackage ./writeTOML.nix { };
})
