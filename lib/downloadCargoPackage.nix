{ pkgsBuildBuild
, urlForCargoPackage
}:

let
  inherit (pkgsBuildBuild)
    fetchurl
    runCommand;
in
{ name
, version
, checksum
, ...
}@args:
let
  pkgInfo = urlForCargoPackage args;
  tarball = fetchurl (pkgInfo.fetchurlExtraArgs // {
    inherit (pkgInfo) url;
    name = "${name}-${version}";
    sha256 = checksum;
  });
in
runCommand "cargo-package-${name}-${version}" { } ''
  mkdir -p $out
  tar -xzf ${tarball} -C $out --strip-components=1
  echo '{"files":{}, "package":"${checksum}"}' > $out/.cargo-checksum.json
''
