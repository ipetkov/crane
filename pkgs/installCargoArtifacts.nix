{ makeSetupHook
, pkgsBuildBuild
}:

makeSetupHook
{
  name = "installCargoArtifactsHook";
  substitutions = {
    zstd = "${pkgsBuildBuild.zstd}/bin/zstd";
  };
} ./installCargoArtifactsHook.sh
