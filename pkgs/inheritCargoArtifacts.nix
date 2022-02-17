{ makeSetupHook
, pkgsBuildBuild
}:

makeSetupHook
{
  name = "inheritCargoArtifactsHook";
  substitutions = {
    zstd = "${pkgsBuildBuild.zstd}/bin/zstd";
  };
} ./inheritCargoArtifactsHook.sh

