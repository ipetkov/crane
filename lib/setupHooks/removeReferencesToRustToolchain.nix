{ lib
, pkgs
, makeSetupHook
,
}:
makeSetupHook
{
  name = "removeReferencesToRustToolchain";
  substitutions = {
    storeDir = builtins.storeDir;
  };
} ./removeReferencesToRustToolchain.sh 
