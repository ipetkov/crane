# Allow the caller to inject their own "callPackage" scope.
# This allows us to both import our packages as an overlay or flake packages,
# as well as importing them within our library scope (in a way that will also
# honor any configuration done via `lib.overrideScope').
#
# Also, worth noting that we need to pass everything through `callPackage`
# so that we can automatically get package splicing (i.e. when cross compiling
# inputs will automatically be taken from the right pkgsBuildHost, pkgsHostTarget,
# etc. scopes).
callPackage:
{
  cargoHelperFunctionsHook = callPackage ./cargoHelperFunctionsHook.nix { };
  configureCargoCommonVarsHook = callPackage ./configureCargoCommonVars.nix { };
  configureCargoVendoredDepsHook = callPackage ./configureCargoVendoredDeps.nix { };
  inheritCargoArtifactsHook = callPackage ./inheritCargoArtifacts.nix { };
  installCargoArtifactsHook = callPackage ./installCargoArtifacts.nix { };
  installFromCargoBuildLogHook = callPackage ./installFromCargoBuildLog.nix { };
  remapSourcePathPrefixHook = callPackage ./remapSourcePathPrefix.nix { };
}
