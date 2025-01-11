{ makeSetupHook
}:
makeSetupHook
{
  name = "removeReferencesToRustToolchainHook";
  substitutions = {
    storeDir = builtins.storeDir;
  };
} ./removeReferencesToRustToolchainHook.sh 
