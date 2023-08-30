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

  examples = suffix: nixpkgs: lib.flip lib.mapAttrs'
    (lib.filterAttrs (_: t: t == "directory") (builtins.readDir ./examples))
    (name: _: {
      name = "example-${name}${suffix}";
      value = {
        dir = "examples/${name}";
        overrideInputs = testInputs // lib.optionalAttrs (nixpkgs != null) {
          inherit nixpkgs;
        } // {
          crane = ./.;
        };
      };
    });

  combined = {
    nixci-examples = lib.fold unionOfDisjoint { } [
      (examples "-stable" null)
      (examples "" nixpkgs-unstable)
    ];
    nixci-examples-darwin = examples "-darwin" (getFlakeRef "nixpkgs-darwin");
    nixci-checks.checks.dir = ".";
    nixci-checks-stable.checks-stable = {
      dir = ".";
      overrideInputs.nixpkgs = testInputs.nixpkgs-stable;
    };
  };
in
unionOfDisjoint combined {
  nixci = lib.foldl unionOfDisjoint { } (builtins.attrValues combined);
}
