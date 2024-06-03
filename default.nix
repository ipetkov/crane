{ pkgs ? import <nixpkgs> { } }:

import ./lib {
  inherit (pkgs) lib makeScopeWithSplicing';
  otherSplices = {
    selfBuildBuild = pkgs.pkgsBuildBuild;
    selfBuildHost = pkgs.pkgsBuildHost;
    selfBuildTarget = pkgs.pkgsBuildTarget;
    selfHostHost = pkgs.pkgsHostHost;
    selfHostTarget = pkgs.pkgsHostTarget;
    selfTargetTarget = pkgs.pkgsTargetTarget;
  };
}
