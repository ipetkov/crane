{ makeSetupHook
, pkgsBuildBuild
}:

makeSetupHook
{
  name = "installFromCargoBuildLogHook";
  substitutions = {
    cargo = "${pkgsBuildBuild.cargo}/bin/cargo";
    jq = "${pkgsBuildBuild.jq}/bin/jq";
  };
} ./installFromCargoBuildLogHook.sh
