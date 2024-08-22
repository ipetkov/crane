{ makeSetupHook
, pkgsBuildBuild
}:

makeSetupHook
{
  name = "installFromCargoBuildLogHook";
  substitutions = {
    jq = "${pkgsBuildBuild.jq}/bin/jq";
  };
} ./installFromCargoBuildLogHook.sh
