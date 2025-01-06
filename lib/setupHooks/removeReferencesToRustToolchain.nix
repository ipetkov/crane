{
  lib,
  makeSetupHook,
}:
  makeSetupHook { name = "removeReferencesToRustToolchain"; } ./removeReferencesToRustToolchain.sh 
