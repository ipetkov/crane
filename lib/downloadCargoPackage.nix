{ fetchurl
, urlForCargoPackage
, runCommand
}:

{ name
, version
, checksum
, source
, ...
}:
let
  tarball = fetchurl {
    name = "${name}-${version}";
    sha256 = checksum;
    url = urlForCargoPackage {
      inherit name version source;
    };
  };
in
runCommand "cargo-package-${name}-${version}" { } ''
  mkdir -p $out
  tar -xzf ${tarball} -C $out --strip-components=1
  echo '{"files":{}, "package":"${checksum}"}' > $out/.cargo-checksum.json
''
