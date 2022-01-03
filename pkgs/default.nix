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

  copyCargoTargetToOutputHook = makeSetupHook
    {
      name = "copyCargoTargetToOutputHook";
      substitutions = {
        zstd = "${zstd}/bin/zstd";
      };
    } ./copyCargoTargetToOutputHook.sh;

  inheritCargoArtifactsHook = makeSetupHook
    {
      name = "inheritCargoArtifactsHook";
      substitutions = {
        zstd = "${zstd}/bin/zstd";
      };
    } ./inheritCargoArtifactsHook.sh;

  installFromCargoArtifactsHook = makeSetupHook
    {
      name = "installFromCargoArtifactsHook";
    } ./installFromCargoArtifactsHook.sh;

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
