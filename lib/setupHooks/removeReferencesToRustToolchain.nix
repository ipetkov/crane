{ makeSetupHook
, rustc
}:
makeSetupHook
{
  name = "removeReferencesToRustToolchainHook";
  substitutions = {
    storeDir = builtins.storeDir;
  };
  propagatedBuildInputs = [ rustc ];
} ./removeReferencesToRustToolchainHook.sh 
