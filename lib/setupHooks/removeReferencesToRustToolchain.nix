{
  lib,
  pkgs,
  makeSetupHook,
}:
makeSetupHook { 
  name = "removeReferencesToRustToolchain"; 
  substitutions = {
    storeDir = builtins.storeDir;
  };
  propagatedBuildInputs = [ pkgs.ripgrep ];
} ./removeReferencesToRustToolchain.sh 
