{ myLib
, pkgs
, runCommand
, stdenv
, wasm-bindgen-cli
}:

let
  wasmToolchain = pkgs.rust-bin.stable.latest.minimal.override {
    targets = [ "wasm32-unknown-unknown" ];
  };

  tarball = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/4e6868b1aa3766ab1de169922bb3826143941973.tar.gz";
    sha256 = "sha256:1q6bj2jjlwb10sfrhqmjpzsc3yc4x76cvky16wh0z52p7d2lhdpv";
  };
  myLibWasm = (myLib.overrideToolchain wasmToolchain).overrideScope (_final: _prev: {
    inherit (import tarball { inherit (stdenv) system; }) wasm-bindgen-cli;
  });

  defaultArgs = {
    src = ./trunk;
    doCheck = false;
    wasm-bindgen-cli = pkgs.wasm-bindgen-cli.override {
      version = "0.2.90";
      hash = "sha256-X8+DVX7dmKh7BgXqP7Fp0smhup5OO8eWEhn26ODYbkQ=";
      cargoHash = "sha256-ckJxAR20GuVGstzXzIj1M0WBFj5eJjrO2/DRMUK5dwM=";
    };
  };

  # default build
  cargoArtifacts = myLibWasm.buildDepsOnly (defaultArgs // {
    CARGO_BUILD_TARGET = "wasm32-unknown-unknown";
  });
  trunkSimple = myLibWasm.buildTrunkPackage (defaultArgs // {
    inherit cargoArtifacts;
    pname = "trunk-simple";
  });

  trunkSimpleNoArtifacts = myLibWasm.buildTrunkPackage (defaultArgs // {
    pname = "trunk-simple-no-artifacts";
  });

  trunkOutdatedBindgen = myLibWasm.buildTrunkPackage {
    pname = "trunk-outdated-bindgen";
    src = ./trunk-outdated-bindgen;
    doCheck = false;
    wasm-bindgen-cli = pkgs.wasm-bindgen-cli.override {
      version = "0.2.85";
      hash = "sha256-0pTIzpu7dJM34CXmi83e8UV0E3N2bKJiOMw5WJQ2s/Y=";
      cargoHash = "sha256-ZwmoFKmGaf5VvTTXjLyb2714Pu536E/8UxUzxI40ID8=";
    };
  };
in
runCommand "trunkTests" { } ''
  test -f ${trunkSimple}/*.wasm
  test -f ${trunkSimple}/*.css
  test -f ${trunkSimpleNoArtifacts}/*.wasm
  test -f ${trunkOutdatedBindgen}/*.wasm
  mkdir -p $out
''
