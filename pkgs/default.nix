{ makeSetupHook
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
        rsync = "${rsync}/bin/rsync";
        zstd = "${zstd}/bin/zstd";
      };
    } ./inheritCargoArtifactsHook.sh;

  installFromCargoArtifactsHook = makeSetupHook
    {
      name = "installFromCargoArtifactsHook";
    } ./installFromCargoArtifactsHook.sh;
}
