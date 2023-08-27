{ inputs }:

let
  lib = inputs.nixpkgs.lib;

  getTarball = nodes: node:
    let
      locked = nodes.${node}.locked;
      inherit (locked) type owner repo rev narHash;
    in
    builtins.fetchTarball {
      url = "https://github.com/${owner}/${repo}/archive/${rev}.tar.gz";
      sha256 = narHash;
    };

  nixpkgs-unstable = getTarball
    (builtins.fromJSON (builtins.readFile ./flake.lock)).nodes
    "nixpkgs";

  testInputs =
    let
      nodes = (builtins.fromJSON (builtins.readFile ./tests/flake.lock)).nodes;
    in
    lib.flip lib.mapAttrs nodes.root.inputs (_: getTarball nodes);

  examples = stable: lib.flip lib.mapAttrs'
    (lib.filterAttrs (_: t: t == "directory") (builtins.readDir ./examples))
    (name: _: {
      name = "example-${name}${lib.optionalString stable "-stable"}";
      value = {
        dir = "examples/${name}";
        overrideInputs = testInputs // lib.optionalAttrs (!stable) {
          nixpkgs = nixpkgs-unstable;
        } // {
          crane = ./.;
        };
      };
    });
in
lib.foldl lib.attrsets.unionOfDisjoint
{
  checks.dir = ".";
  checks-stable = {
    dir = ".";
    overrideInputs.nixpkgs = testInputs.nixpkgs-stable;
  };
}
  [
    (examples true)
    (examples false)
  ]
