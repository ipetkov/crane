{ pkgsBuildBuild
, urlForCargoPackage
}:

let
  inherit (pkgsBuildBuild)
    fetchurl
    stdenv;
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
stdenv.mkDerivation {
  inherit version;
  pname = "cargo-package-${name}";

  dontConfigure = true;
  dontBuild = true;

  unpackPhase = ''
    runHook preUnpack
    mkdir -p crate
    tar -xzf ${tarball} --strip-components=1
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r -t $out .
    echo '{"files":{}, "package":"${checksum}"}' > $out/.cargo-checksum.json
    runHook postInstall
  '';
}
