{ fetchurl
, urlForCargoPackage
, runCommand
, lib
}:

{ shardName, packages }:
let
  getTarball = ({ name, version, checksum, ... }@args:
    let
      pkgInfo = urlForCargoPackage args;
    in
    {
      inherit name version checksum;
      tarball = fetchurl (pkgInfo.fetchurlExtraArgs // {
        inherit (pkgInfo) url;
        name = "${name}-${version}";
        sha256 = checksum;
      });
    });

  tarballs = map getTarball packages;

  extract = (tarball:
    let outPath = "$out/${lib.escapeShellArg "${tarball.name}-${tarball.version}"}";
    in ''
      mkdir -p ${outPath}
      tar -xf ${tarball.tarball} -C ${outPath} --strip-components=1
      echo '{"files":{}, "package":"${tarball.checksum}"}' > ${outPath}/.cargo-checksum.json
    '');

  name = if builtins.stringLength shardName == 0 then "extract-cargo-packages" else "extract-cargo-packages-${shardName}";
in
runCommand name { } ''
  mkdir -p $out
  ${lib.strings.concatMapStrings extract tarballs}
''
