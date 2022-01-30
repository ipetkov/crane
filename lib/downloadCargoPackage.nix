{ fetchurl
, urlForCargoPackage
, runCommandLocal
}:

{ name
, version
, checksum
, source
, ...
}@args:
let
  tarball = fetchurl {
    name = "${name}-${version}";
    sha256 = checksum;
    url = urlForCargoPackage args;
  };
in
runCommandLocal "cargo-package-${name}-${version}" { } ''
  mkdir -p $out
  tar -xzf ${tarball} -C $out --strip-components=1
  echo '{"files":{}, "package":"${checksum}"}' > $out/.cargo-checksum.json
''
