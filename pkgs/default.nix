myLib:
let
  mkDeprecated = name:
    builtins.trace "packages.${name} is deprecated, please use craneLib.${name} instead"
      myLib.${name};
in
{
  cargoHelperFunctionsHook = mkDeprecated "cargoHelperFunctionsHook";
  configureCargoCommonVarsHook = mkDeprecated "configureCargoCommonVarsHook";
  configureCargoVendoredDepsHook = mkDeprecated "configureCargoVendoredDepsHook";
  inheritCargoArtifactsHook = mkDeprecated "inheritCargoArtifactsHook";
  installCargoArtifactsHook = mkDeprecated "installCargoArtifactsHook";
  installFromCargoBuildLogHook = mkDeprecated "installFromCargoBuildLogHook";
  removeReferencesToVendoredSourcesHook = mkDeprecated "removeReferencesToVendoredSourcesHook";
}
