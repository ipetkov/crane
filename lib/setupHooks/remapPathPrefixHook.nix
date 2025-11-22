{
  makeSetupHook,
}:
makeSetupHook {
  name = "remapPathPrefixHook";
  substitutions = {
    storeDir = builtins.storeDir;
  };
} ./remapPathPrefixHook.sh
