{ inputs }:

let
  lib = inputs.nixpkgs.lib;
  inherit (lib.attrsets) unionOfDisjoint;

  getTarball = nodes: node:
    let
      locked = nodes.${node}.locked;
      inherit (locked) type owner repo rev narHash;
    in
    "${type}:${owner}/${repo}/${rev}";

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

  nixci-examples = lib.fold unionOfDisjoint {} [
    (examples true)
    (examples false)
  ];

  nixci-checks.checks.dir = ".";
  nixci-checks-stable.checks-stable = {
    dir = ".";
    overrideInputs.nixpkgs = testInputs.nixpkgs-stable;
  };

  combined = {
    inherit
      nixci-checks
      nixci-checks-stable
      nixci-examples;
    };
in
unionOfDisjoint combined {
  nixci = lib.foldl unionOfDisjoint {} (builtins.attrValues combined);
}
