{ lib
}:

# https://doc.rust-lang.org/cargo/reference/registries.html
{ dl
, indexUrl
, registryPrefix ? "registry+"
, fetchurlExtraArgs ? { }
}:
let
  matches = m: builtins.match ".*${lib.escapeRegex m}.*" dl;
  hasMarker = lib.any (m: null != matches m) [
    "{crate}"
    "{version}"
    "{prefix}"
    "{lowerprefix}"
    "{sha256-checksum}"
  ];

  fullDownloadUrl = if hasMarker then dl else "${dl}/{crate}/{version}/download";

  registryIndexUrl =
    if lib.hasPrefix registryPrefix indexUrl
    then indexUrl
    else "${registryPrefix}${indexUrl}";
in
{
  "${registryIndexUrl}" = {
    inherit fetchurlExtraArgs;
    downloadUrl = fullDownloadUrl;
  };
}
