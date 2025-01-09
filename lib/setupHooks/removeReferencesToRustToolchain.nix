{ lib
, pkgs
, rustc
, makeSetupHook
,
}:
makeSetupHook
{
  name = "removeReferencesToRustToolchain";
  substitutions = {
    storeDir = builtins.storeDir;
  };
  propagatedBuildInputs = [ rustc ];
} ./removeReferencesToRustToolchain.sh 
