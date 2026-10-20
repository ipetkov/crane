{
  makeSetupHook,
  lib,
  nukeRefsTo,
}:
makeSetupHook {
  name = "removeReferencesToRustToolchainHook";
  substitutions = {
    storeDir = builtins.storeDir;
    inherit nukeRefsTo;
  };
} ./removeReferencesToRustToolchainHook.sh
