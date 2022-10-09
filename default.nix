{ pkgs ? import <nixpkgs> { } }:

import ./lib {
  inherit (pkgs) lib newScope;
}
