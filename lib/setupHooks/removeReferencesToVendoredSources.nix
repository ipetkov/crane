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
        echo signing files:
        while IFS= read -r -d $'\0' file; do
          echo "signing: $file"
          signIfRequired "$file"
        done < <(find "''${installLocation}" -type f -print0)
        echo signing done
      fi
    '';
  };
} ./removeReferencesToVendoredSourcesHook.sh
