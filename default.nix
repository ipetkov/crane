{ pkgs ? import <nixpkgs> { } }:

import ./lib {
  inherit (pkgs) lib newScope;
  mkMyPkgs = callPackage: import ./pkgs callPackage;
}
