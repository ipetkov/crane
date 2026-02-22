{
  lib,
  myLib,
  pkgs,
  runCommand,
  stdenv,
  wasm-bindgen-cli_0_2_108,
}:

# FIXME: revisit
let
  wasmToolchainFor =
    p:
    p.rust-bin.stable.latest.minimal.override {
      targets = [ "wasm32-unknown-unknown" ];
    };

  tarball = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/4e6868b1aa3766ab1de169922bb3826143941973.tar.gz";
    sha256 = "sha256:1q6bj2jjlwb10sfrhqmjpzsc3yc4x76cvky16wh0z52p7d2lhdpv";
  };
  myLibWasm = (myLib.overrideToolchain wasmToolchainFor).overrideScope (
    _final: _prev: {
      inherit (import tarball { inherit (stdenv) system; }) wasm-bindgen-cli;
    }
  );

  defaultArgs = {
    src = ./trunk;
    doCheck = false;
    wasm-bindgen-cli = wasm-bindgen-cli_0_2_108;
  };

  # default build
  cargoArtifacts = myLibWasm.buildDepsOnly (
    defaultArgs
    // {
      CARGO_BUILD_TARGET = "wasm32-unknown-unknown";
    }
  );
  trunkSimple = myLibWasm.buildTrunkPackage (
    defaultArgs
    // {
      inherit cargoArtifacts;
      pname = "trunk-simple";
    }
  );

  trunkSimpleNoArtifacts = myLibWasm.buildTrunkPackage (
    defaultArgs
    // {
      pname = "trunk-simple-no-artifacts";
    }
  );

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
