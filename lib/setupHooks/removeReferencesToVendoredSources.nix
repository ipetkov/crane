{ darwin
, lib
, makeSetupHook
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
    sourceSigningUtils = if darwinCodeSign then "source ${darwin.signingUtils}" else null;
    signIfRequired = if darwinCodeSign then ''if [ -z "''${doNotSign-}" ]; then signIfRequired "''${installedFile}"; fi'' else null;
  };
} ./removeReferencesToVendoredSourcesHook.sh
