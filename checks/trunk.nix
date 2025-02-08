{ lib
, myLib
, pkgs
, runCommand
, stdenv
}:

let
  wasmToolchainFor = p: p.rust-bin.stable.latest.minimal.override {
    targets = [ "wasm32-unknown-unknown" ];
  };

  tarball = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/4e6868b1aa3766ab1de169922bb3826143941973.tar.gz";
    sha256 = "sha256:1q6bj2jjlwb10sfrhqmjpzsc3yc4x76cvky16wh0z52p7d2lhdpv";
  };
  myLibWasm = (myLib.overrideToolchain wasmToolchainFor).overrideScope (_final: _prev: {
    inherit (import tarball { inherit (stdenv) system; }) wasm-bindgen-cli;
  });

  defaultArgs = {
    src = ./trunk;
    doCheck = false;
    wasm-bindgen-cli = pkgs.buildWasmBindgenCli rec {
      src = pkgs.fetchCrate {
        pname = "wasm-bindgen-cli";
        version = "0.2.92";
        hash = "sha256-1VwY8vQy7soKEgbki4LD+v259751kKxSxmo/gqE6yV0=";
      };

      cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
        inherit src;
        inherit (src) pname version;
        hash = "sha256-81vQkKubMWaX0M3KAwpYgMA1zUQuImFGvh5yTW+rIAs=";
      };
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

  body = lib.optionalString (pkgs ? buildWasmBindgenCli) ''
    test -f ${trunkSimple}/*.wasm
    test -f ${trunkSimple}/*.css
    test -f ${trunkSimpleNoArtifacts}/*.wasm
  '';
in
runCommand "trunkTests" { } ''
  ${body}
  touch $out
''
