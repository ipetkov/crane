{ inputs }:

let
  lib = inputs.nixpkgs.lib;
  inherit (lib.attrsets) unionOfDisjoint;

  getFlakeRefFrom = nodes: node:
    let
      locked = nodes.${node}.locked;
      inherit (locked) type owner repo rev narHash;
    in
    "${type}:${owner}/${repo}/${rev}";

  nixpkgs-unstable = getFlakeRefFrom
    (builtins.fromJSON (builtins.readFile ./flake.lock)).nodes
    "nixpkgs";

  nodes = (builtins.fromJSON (builtins.readFile ./tests/flake.lock)).nodes;
  getFlakeRef = getFlakeRefFrom nodes;
  testInputs = lib.flip lib.mapAttrs nodes.root.inputs (_: getFlakeRef);
  inherit (testInputs) nixpkgs-stable;

  examples = suffix: nixpkgs: lib.flip lib.mapAttrs'
    (lib.filterAttrs (_: t: t == "directory") (builtins.readDir ./examples))
    (name: _: {
      name = "example-${name}${suffix}";
      value = {
        dir = "examples/${name}";
        overrideInputs = testInputs // {
          inherit nixpkgs;
          crane = ./.;
        };
      };
    });

  combined = {
    nixci-checks = unionOfDisjoint (examples "" nixpkgs-unstable) {
      checks.dir = ".";
    };

    nixci-checks-stable = unionOfDisjoint (examples "-stable" nixpkgs-stable) {
      checks-stable = {
        dir = ".";
        overrideInputs.nixpkgs = nixpkgs-stable;
      };
    };

    nixci-darwin = examples "-darwin" (getFlakeRef "nixpkgs-darwin");
  };
in
unionOfDisjoint combined {
  nixci = lib.foldl unionOfDisjoint { } (builtins.attrValues combined);
}
