{ registryFromDownloadUrl }:

{ indexUrl
, sha256
, fetchurlExtraArgs ? { }
}:

let
  configContents = builtins.readFile "${builtins.fetchurl {
    inherit sha256;
    url = "${indexUrl}config.json";
  }}";

  config = builtins.fromJSON configContents;
  dl = config.dl or (throw ''
    registry config does not have a "dl" endpoint:
    ${configContents}
  '');
in
registryFromDownloadUrl {
  inherit dl indexUrl fetchurlExtraArgs;
  registryPrefix = "sparse+";
}
