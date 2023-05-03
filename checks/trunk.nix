{ pkgs
, myLib
, runCommand
}:

let
  wasmToolchain = pkgs.rust-bin.stable.latest.minimal.override {
    targets = [ "wasm32-unknown-unknown" ];
  };

  myLibWasm = myLib.overrideToolchain wasmToolchain;

  defaultArgs = {
    src = ./trunk;
    doCheck = false;
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
in
runCommand "trunkTests" { } ''
  test -f ${trunkSimple}/*.wasm
  test -f ${trunkSimple}/*.css
  test -f ${trunkSimpleNoArtifacts}/*.wasm
  mkdir -p $out
''
