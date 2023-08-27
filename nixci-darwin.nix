{ inputs }:

let
  lib = inputs.nixpkgs.lib;
  nodes = (builtins.fromJSON (builtins.readFile ./tests/flake.lock)).nodes;

  getTarball = node:
    let
      locked = nodes.${node}.locked;
      inherit (locked) type owner repo rev narHash;
    in
    builtins.fetchTarball {
      url = "https://github.com/${owner}/${repo}/archive/${rev}.tar.gz";
      sha256 = narHash;
    };

  nixpkgs-darwin = getTarball "nixpkgs-darwin";
  testInputs = lib.flip lib.mapAttrs nodes.root.inputs (_: getTarball);

  examples = lib.flip lib.mapAttrs'
    (lib.filterAttrs (_: t: t == "directory") (builtins.readDir ./examples))
    (name: _: {
      name = "example-${name}";
      value = {
        dir = "examples/${name}";
        overrideInputs = testInputs // {
          crane = ./.;
          nixpkgs = nixpkgs-darwin;
        };
      };
    });
in
examples
