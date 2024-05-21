{ lib
, makeSetupHook
, pkgsBuildBuild
, stdenv
, parallel
}:

let
  darwinCodeSign = stdenv.targetPlatform.isDarwin && stdenv.targetPlatform.isAarch64;
in
makeSetupHook
{
  name = "removeReferencesToVendoredSourcesHook";
  propagatedBuildInputs = [parallel];
  substitutions = {
    storeDir = builtins.storeDir;
    sourceSigningUtils = lib.optionalString darwinCodeSign ''
      source ${pkgsBuildBuild.darwin.signingUtils}
    '';
    signIfRequired = lib.optionalString darwinCodeSign ''
      if [ -n "''${doNotSign-}" ]; then
        echo "not signing ''${installedFile} as requested";
      else
        signIfRequired "''${installedFile}"
      fi
    '';
  };
} ./removeReferencesToVendoredSourcesHook.sh
