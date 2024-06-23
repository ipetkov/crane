{ pkgs ? import <nixpkgs> { } }:

import ./lib {
  inherit (pkgs)
    lib
    makeScopeWithSplicing'
    splicePackages
    pkgsBuildBuild
    pkgsBuildHost
    pkgsBuildTarget
    pkgsHostHost
    pkgsHostTarget
    pkgsTargetTarget;
}
