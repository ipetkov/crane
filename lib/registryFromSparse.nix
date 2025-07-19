{
  registryFromDownloadUrl,
  lib,
  pkgsBuildBuild,
}:

{
  indexUrl,
  configSha256,
  fetchurlExtraArgs ? { },
}:

let
  inherit (pkgsBuildBuild) fetchurl;

  slashTerminatedIndexUrl = if lib.hasSuffix "/" indexUrl then indexUrl else "${indexUrl}/";
  configContents = builtins.readFile "${fetchurl (
    fetchurlExtraArgs
    // {
      url = "${slashTerminatedIndexUrl}config.json";
      sha256 = configSha256;
    }
  )}";

  config = builtins.fromJSON configContents;
  dl =
    config.dl or (throw ''
      registry config does not have a "dl" endpoint:
      ${configContents}
    '');
in
registryFromDownloadUrl {
  inherit dl fetchurlExtraArgs;
  registryPrefix = "sparse+";
  indexUrl = slashTerminatedIndexUrl;
}
