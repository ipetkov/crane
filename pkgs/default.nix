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

    inheritCargoTargetHook = makeSetupHook
    {
      name = "inheritCargoTargetHook";
      substitutions = {
        rsync = "${rsync}/bin/rsync";
        zstd = "${zstd}/bin/zstd";
      };
    } ./inheritCargoTargetHook.sh;
}
