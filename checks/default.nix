{ myLib }:

let
  callPackage = myLib.newScope { };
in
{
  nixpkgs-fmt = callPackage ./nixpkgs-fmt.nix { };

  cleanCargoTomlSimple = callPackage ./cleanCargoToml/simple { };
  cleanCargoTomlComplex = callPackage ./cleanCargoToml/complex { };
}
