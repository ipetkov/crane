{ cargo
, makeSetupHook
, jq
, rsync
, zstd
}:

{
  configureCargoCommonVarsHook = makeSetupHook
    {
      name = "configureCargoCommonVarsHook";
    } ./configureCargoCommonVarsHook.sh;

  configureCargoVendoredDepsHook = makeSetupHook
    {
      name = "configureCargoVendoredDepsHook";
    } ./configureCargoVendoredDepsHook.sh;

  inheritCargoArtifactsHook = makeSetupHook
    {
      name = "inheritCargoArtifactsHook";
      substitutions = {
        zstd = "${zstd}/bin/zstd";
      };
    } ./inheritCargoArtifactsHook.sh;

  installCargoTargetDirHook = makeSetupHook
    {
      name = "installCargoTargetDirHook";
      substitutions = {
        zstd = "${zstd}/bin/zstd";
      };
    } ./installCargoTargetDirHook.sh;

  installFromCargoBuildLogHook = makeSetupHook
    {
      name = "installFromCargoBuildLogHook";
      substitutions = {
        cargo = "${cargo}/bin/cargo";
        jq = "${jq}/bin/jq";
      };
    } ./installFromCargoBuildLogHook.sh;

  remapSourcePathPrefixHook = makeSetupHook
    {
      name = "remapSourcePathPrefixHook";
    } ./remapSourcePathPrefixHook.sh;
}
