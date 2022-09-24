{ makeSetupHook
, pkgsBuildBuild
}:

makeSetupHook
{
  name = "removeReferencesToVendoredSourcesHook";
  substitutions = {
    storeDir = builtins.storeDir;
  };
  deps = with pkgsBuildBuild; [
    removeReferencesTo
  ];
} ./removeReferencesToVendoredSourcesHook.sh
