{ makeSetupHook
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
}
