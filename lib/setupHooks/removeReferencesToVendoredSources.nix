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
        echo "not signing as requested";
      else
        (
          exec 3>&1
          echo signing files:
          find "''${installLocation}" -type f |
            sort |
            tee -a /dev/fd/3 |
            xargs --no-run-if-empty signIfRequired
          echo signing done
        )
      fi
    '';
  };
} ./removeReferencesToVendoredSourcesHook.sh
