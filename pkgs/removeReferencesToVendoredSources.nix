{ makeSetupHook
}:

makeSetupHook
{
  name = "removeReferencesToVendoredSourcesHook";
  substitutions = {
    storeDir = builtins.storeDir;
  };
} ./removeReferencesToVendoredSourcesHook.sh
