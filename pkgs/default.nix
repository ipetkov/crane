{ cargo
, makeSetupHook
, jq
, rsync
, pkgsBuildBuild
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
        zstd = "${pkgsBuildBuild.zstd}/bin/zstd";
      };
    } ./inheritCargoArtifactsHook.sh;

  installCargoArtifactsHook = makeSetupHook
    {
      name = "installCargoArtifactsHook";
      substitutions = {
        zstd = "${pkgsBuildBuild.zstd}/bin/zstd";
      };
    } ./installCargoArtifactsHook.sh;

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
