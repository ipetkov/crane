{ pkgs ? import <nixpkgs> { } }:

pkgs.callPackage ./lib { }
