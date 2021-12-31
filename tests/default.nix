{ system ? builtins.currentSystem }:

let
  flake = import ../default.nix;
  myLib = flake.lib.${system};
  pkgs = import flake.inputs.nixpkgs {
    inherit system;
  };
in
pkgs.lib.makeScope myLib.newScope (self:
  let
    callPackage = self.newScope { };
  in
  {
    cleanCargoTomlSimple = callPackage ./cleanCargoToml/simple { };
    cleanCargoTomlComplex = callPackage ./cleanCargoToml/complex { };
  })
