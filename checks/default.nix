{ myLib }:

let
  callPackage = myLib.newScope { };
in
{
  nixpkgs-fmt = callPackage ./nixpkgs-fmt.nix { };
}
