{ lib
, makeSetupHook
, pkgsBuildBuild
, stdenv
}:

let
  darwinCodeSign = stdenv.targetPlatform.isDarwin && stdenv.targetPlatform.isAarch64;
in
makeSetupHook
{
  name = "removeReferencesToVendoredSourcesHook";
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
