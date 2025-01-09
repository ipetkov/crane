{ lib
, stdenv
, makeScopeWithSplicing'
, splicePackages
, pkgsBuildBuild
, pkgsBuildHost
, pkgsBuildTarget
, pkgsHostHost
, pkgsHostTarget
, pkgsTargetTarget
}:

let
  minSupported = "24.11";
  current = lib.concatStringsSep "." (lib.lists.sublist 0 2 (lib.splitVersion lib.version));
  isUnsupported = lib.versionOlder current minSupported;
  msg = "crane requires at least nixpkgs-${minSupported}, supplied nixpkgs-${current}";

  # Helps keep things in sync between `overrideToolchain` and `keep`
  attrsForToolchainOverride = [
    "cargo"
    "clippy"
    "rustc"
    "rustfmt"
  ];

  spliceToolchain = toolchainFn:
    let
      splices = {
        pkgsBuildBuild = { toolchain = toolchainFn pkgsBuildBuild; };
        pkgsBuildHost = { toolchain = toolchainFn pkgsBuildHost; };
        pkgsBuildTarget = { toolchain = toolchainFn pkgsBuildTarget; };
        pkgsHostHost = { toolchain = toolchainFn pkgsHostHost; };
        pkgsHostTarget = { toolchain = toolchainFn pkgsHostTarget; };
        pkgsTargetTarget = lib.optionalAttrs (pkgsTargetTarget?newScope) { toolchain = toolchainFn pkgsTargetTarget; };
      };
    in
    (splicePackages splices).toolchain;

  scopeFn = self:
    let
      inherit (self) callPackage;

      internalCrateNameFromCargoToml = callPackage ./internalCrateNameFromCargoToml.nix { };
      internalCrateNameForCleanSource = callPackage ./internalCrateNameForCleanSource.nix {
        inherit internalCrateNameFromCargoToml;
      };
      internalPercentDecode = callPackage ./internalPercentDecode.nix { };
    in
    {
      appendCrateRegistries = input: self.overrideScope (_final: prev: {
        crateRegistries = prev.crateRegistries // (lib.foldl (a: b: a // b) { } input);
      });

      buildDepsOnly = callPackage ./buildDepsOnly.nix { };
      buildPackage = callPackage ./buildPackage.nix { };
      buildTrunkPackage = callPackage ./buildTrunkPackage.nix { };
      cargoAudit = callPackage ./cargoAudit.nix { };
      cargoBuild = callPackage ./cargoBuild.nix { };
      cargoClippy = callPackage ./cargoClippy.nix { };
      cargoDeny = callPackage ./cargoDeny.nix { };
      cargoDoc = callPackage ./cargoDoc.nix { };
      cargoDocTest = callPackage ./cargoDocTest.nix { };
      cargoFmt = callPackage ./cargoFmt.nix { };
      cargoHelperFunctionsHook = callPackage ./setupHooks/cargoHelperFunctions.nix { };
      cargoLlvmCov = callPackage ./cargoLlvmCov.nix { };
      cargoNextest = callPackage ./cargoNextest.nix { };
      cargoTarpaulin = callPackage ./cargoTarpaulin.nix { };
      cargoTest = callPackage ./cargoTest.nix { };
      cleanCargoSource = callPackage ./cleanCargoSource.nix {
        inherit internalCrateNameForCleanSource;
      };
      cleanCargoToml = callPackage ./cleanCargoToml.nix { };
      configureCargoCommonVarsHook = callPackage ./setupHooks/configureCargoCommonVars.nix { };
      configureCargoVendoredDepsHook = callPackage ./setupHooks/configureCargoVendoredDeps.nix { };
      craneLib = self;
      craneUtils = callPackage ../pkgs/crane-utils { };

      crateNameFromCargoToml = callPackage ./crateNameFromCargoToml.nix {
        inherit internalCrateNameFromCargoToml;
      };

      crateRegistries = self.registryFromDownloadUrl {
        dl = "https://static.crates.io/crates";
        indexUrl = "https://github.com/rust-lang/crates.io-index";
      };

      devShell = callPackage ./devShell.nix { };
      downloadCargoPackage = callPackage ./downloadCargoPackage.nix { };
      downloadCargoPackageFromGit = callPackage ./downloadCargoPackageFromGit.nix { };
      filterCargoSources = callPackage ./filterCargoSources.nix { };

      fileset = {
        cargoTomlAndLock = callPackage ./fileset/cargoTomlAndLock.nix { };
        commonCargoSources = callPackage ./fileset/commonCargoSources.nix { };
        configToml = callPackage ./fileset/configToml.nix { };
        rust = callPackage ./fileset/rust.nix { };
        toml = callPackage ./fileset/toml.nix { };
      };

      findCargoFiles = callPackage ./findCargoFiles.nix { };
      inheritCargoArtifactsHook = callPackage ./setupHooks/inheritCargoArtifacts.nix { };
      installCargoArtifactsHook = callPackage ./setupHooks/installCargoArtifacts.nix { };
      installFromCargoBuildLogHook = callPackage ./setupHooks/installFromCargoBuildLog.nix { };
      mkCargoDerivation = callPackage ./mkCargoDerivation.nix { };
      mkDummySrc = callPackage ./mkDummySrc.nix { };

      overrideToolchain = toolchainArg: self.overrideScope (_final: _prev:
        let
          toolchain =
            if lib.isFunction toolchainArg
            then spliceToolchain toolchainArg
            else toolchainArg;
          needsSplicing = stdenv.buildPlatform != stdenv.hostPlatform && toolchain?__spliced == false;
          warningMsg = ''
            craneLib.overrideToolchain requires a spliced toolchain when cross-compiling. Consider specifying
            a function which constructs a toolchain for any given `pkgs` instantiation:

            (crane.mkLib pkgs).overrideToolchain (p: ...)
          '';
        in
        lib.warnIf needsSplicing warningMsg (lib.genAttrs attrsForToolchainOverride (_: toolchain))
      );

      path = callPackage ./path.nix {
        inherit internalCrateNameForCleanSource;
      };

      registryFromDownloadUrl = callPackage ./registryFromDownloadUrl.nix { };
      registryFromGitIndex = callPackage ./registryFromGitIndex.nix { };
      registryFromSparse = callPackage ./registryFromSparse.nix { };
      removeReferencesToRustToolchainHook = callPackage ./setupHooks/removeReferencesToRustToolchain.nix { };
      removeReferencesToVendoredSourcesHook = callPackage ./setupHooks/removeReferencesToVendoredSources.nix { };
      replaceCargoLockHook = callPackage ./setupHooks/replaceCargoLockHook.nix { };
      taploFmt = callPackage ./taploFmt.nix { };
      urlForCargoPackage = callPackage ./urlForCargoPackage.nix { };
      vendorCargoDeps = callPackage ./vendorCargoDeps.nix { };
      vendorMultipleCargoDeps = callPackage ./vendorMultipleCargoDeps.nix { };
      vendorCargoRegistries = callPackage ./vendorCargoRegistries.nix { };
      vendorGitDeps = callPackage ./vendorGitDeps.nix {
        inherit internalPercentDecode;
      };
      writeTOML = callPackage ./writeTOML.nix { };
    };

  craneSpliced = makeScopeWithSplicing' {
    f = scopeFn;
    otherSplices = {
      selfBuildBuild = lib.makeScope pkgsBuildBuild.newScope scopeFn;
      selfBuildHost = lib.makeScope pkgsBuildHost.newScope scopeFn;
      selfBuildTarget = lib.makeScope pkgsBuildTarget.newScope scopeFn;
      selfHostHost = lib.makeScope pkgsHostHost.newScope scopeFn;
      selfHostTarget = lib.makeScope pkgsHostTarget.newScope scopeFn;
      selfTargetTarget = lib.optionalAttrs (pkgsTargetTarget?newScope) (lib.makeScope pkgsTargetTarget.newScope scopeFn);
    };
    keep = self: lib.optionalAttrs (self?cargo)
      (lib.genAttrs attrsForToolchainOverride (n: self.${n}));
  };
in
lib.warnIf isUnsupported msg (craneSpliced)
