{ cleanCargoToml
, findCargoFiles
, lib
, runCommandLocal
, writeText
, writeTOML
}:

{ src
, cargoLock ? src + /Cargo.lock
, ...
}:
let
  inherit (builtins)
    dirOf
    concatStringsSep
    hasAttr
    pathExists;

  inherit (lib)
    optionalString
    removePrefix;

  inherit (lib.strings) concatStrings;

  dummyrs = writeText "dummy.rs" ''
    #![allow(dead_code)]
    pub fn main() {}
  '';

  cpDummy = prefix: path: ''
    mkdir -p ${prefix}/${dirOf path}
    cp -f ${dummyrs} ${prefix}/${path}
  '';

  inherit (findCargoFiles src)
    cargoTomls
    cargoConfigs;

  basePath = (toString src) + "/";
  copyAllCargoConfigs = concatStrings (map
    (p:
      let
        dest = removePrefix basePath (toString p);
      in
      ''
        mkdir -p $out/${dirOf dest}
        cp ${p} $out/${dest}
      ''
    )
    cargoConfigs
  );

  copyAndStubCargoTomls = concatStrings (map
    (p:
      let
        cargoTomlDest = removePrefix basePath (toString p);
        parentDir = "$out/${dirOf cargoTomlDest}";

        trimmedCargoToml = cleanCargoToml {
          cargoToml = p;
        };

        safeStubLib =
          if hasAttr "lib" trimmedCargoToml
          then cpDummy parentDir (trimmedCargoToml.lib.path or "src/lib.rs")
          else "";

        safeStubList = attr: defaultPath:
          let
            targetList = trimmedCargoToml.${attr} or [ ];
            paths = map (t: t.path or "${defaultPath}/${t.name}.rs") targetList;
            commands = map (cpDummy parentDir) paths;
          in
          concatStringsSep "\n" commands;
      in
      ''
        mkdir -p ${parentDir}
        cp ${writeTOML "Cargo.toml" trimmedCargoToml} $out/${cargoTomlDest}
      '' + optionalString (trimmedCargoToml ? package) ''
        # To build build-dependencies
        ${cpDummy parentDir "build.rs"}
        # To build regular and dev dependencies (cargo build + cargo test)
        ${cpDummy parentDir "src/lib.rs"}

        # Stub all other targets in case they have particular feature combinations
        ${safeStubLib}
        ${safeStubList "bench" "benches"}
        ${safeStubList "bin" "src/bin"}
        ${safeStubList "example" "examples"}
        ${safeStubList "test" "tests"}
      ''
    )
    cargoTomls
  );

  copyCargoLock =
    if pathExists cargoLock
    then "cp ${cargoLock} $out/Cargo.lock"
    else "echo could not find Cargo.lock at src root";
in
runCommandLocal "dummy-src" { } ''
  mkdir -p $out
  ${copyCargoLock}
  ${copyAllCargoConfigs}
  ${copyAndStubCargoTomls}
''
