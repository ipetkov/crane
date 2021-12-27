{ makeSetupHook }:

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
    } ./copyCargoTargetToOutputHook.sh;
}
