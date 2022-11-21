{ registryFromDownloadUrl
}:

{ indexUrl
, rev
, fetchurlExtraArgs ? { }
}:

let
  index = builtins.fetchGit {
    inherit rev;
    url = indexUrl;
    shallow = true;
  };

  configPath = "${index}/config.json";
  configContents =
    if builtins.pathExists configPath then
      builtins.readFile configPath
    else
      throw "registry index is missing a config.json file";

  config = builtins.fromJSON configContents;
  dl = config.dl or (throw ''
    registry config does not have a "dl" endpoint:
    ${configContents}
  '');
in
registryFromDownloadUrl {
  inherit dl indexUrl fetchurlExtraArgs;
}
