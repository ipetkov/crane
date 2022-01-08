{ cleanCargoToml
, lib
, runCommand
, writeText
, writeTOML
}:

{ src
, ...
}:
let
  inherit (builtins)
    dirOf
    concatStringsSep
    filter
    hasAttr
    pathExists;

  inherit (lib)
    hasSuffix
    optionalString
    removePrefix;

  inherit (lib.strings) concatStrings;

  cargoLock = src + /Cargo.lock;

  dummyrs = writeText "dummy.rs" ''
    #![allow(dead_code)]
    pub fn main() {}
  '';

  cpDummy = prefix: path: ''
    mkdir -p ${prefix}/${dirOf path}
    cp -f ${dummyrs} ${prefix}/${path}
  '';

  allPaths = lib.filesystem.listFilesRecursive src;

  isCargoToml = path: hasSuffix "Cargo.toml" path;
  isCargoConfig = path:
    let
      p = toString path;
      matches = s: hasSuffix s p;
      # Cargo accepts one of two file names for its configuration.
      # Just copy whatever we find and let cargo sort it out.
      # https://doc.rust-lang.org/cargo/reference/config.html
      isMatch = matches ".cargo/config" || matches ".cargo/config.toml";
    in
    isMatch;

  cargoConfigs = filter isCargoConfig allPaths;
  cargoTomls = filter isCargoToml allPaths;

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
        ${cpDummy parentDir "src/main.rs"}

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
runCommand "dummy-src" { } ''
  mkdir -p $out
  ${copyCargoLock}
  ${copyAllCargoConfigs}
  ${copyAndStubCargoTomls}
''
