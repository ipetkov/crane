{ cleanCargoToml
, lib
, runCommand
, writeText
, writeTOML
}:

{ src ? null
, cargoToml ? src + /Cargo.toml
, cargoLock ? src + /Cargo.lock
, cargoConfig ? src + /.cargo/config
, cargoConfigToml ? src + /.cargo/config.toml
}:
let
  inherit (builtins)
    dirOf
    concatStringsSep
    hasAttr
    pathExists;

  dummyrs = writeText "dummy.rs" ''
    #![allow(dead_code)]
    pub fn main() {}
  '';

  trimmedCargoToml = cleanCargoToml {
    inherit cargoToml;
  };

  p = trimmedCargoToml.package;
  name = "${p.name}-${p.version}-dummy-src";

  copyCargoConfig =
    # the .toml extension is preferred, but the extension-less path takes precedence
    # https://doc.rust-lang.org/cargo/reference/config.html
    if pathExists cargoConfig
    then "cp ${cargoConfig} $out/.cargo"
    else if pathExists cargoConfigToml
    then "cp ${cargoConfigToml} $out/.cargo"
    else "";

  cpDummy = path: ''
    mkdir -p $out/${dirOf path}
    cp -f ${dummyrs} $out/${path}
  '';

  safeStubLib =
    if hasAttr "lib" trimmedCargoToml
    then cpDummy (trimmedCargoToml.lib.path or "src/lib.rs")
    else "";

  safeStubList = attr: defaultPath:
    let
      targetList = trimmedCargoToml.${attr} or [ ];
      paths = map (t: t.path or "${defaultPath}/${t.name}") targetList;
      commands = map cpDummy paths;
    in
    concatStringsSep "\n" commands;
in
runCommand name { } ''
  # Base configuration
  mkdir -p $out/.cargo
  ${copyCargoConfig}
  cp ${writeTOML "Cargo.toml" trimmedCargoToml} $out/Cargo.toml
  cp ${cargoLock} $out/Cargo.lock

  # To build build-dependencies
  ${cpDummy "build.rs"}
  # To build regular and dev dependencies (cargo build + cargo test)
  ${cpDummy "src/main.rs"}

  # Stub all other targets in case they have particular feature combinations
  ${safeStubLib}
  ${safeStubList "bench" "benches"}
  ${safeStubList "bin" "bin"}
  ${safeStubList "example" "examples"}
  ${safeStubList "test" "tests"}
''
