{ pkgs ? import <nixpkgs> { }
, lib ? pkgs.callPackage ({ lib }: lib) { }
, toolchainFn ? (pkgs: pkgs)
, otherSplices ? null
}:

let
  otherSpliceFn = pkgs:
    let toolchain = toolchainFn pkgs;
    in lib.makeScope pkgs.newScope (_self: {
      cargo = toolchain;
      clippy = toolchain;
      rustc = toolchain;
      rustfmt = toolchain;
    });
in
pkgs.callPackage ./lib {
  otherSplices =
    if otherSplices != null then otherSplices
    else {
      selfBuildBuild = otherSpliceFn pkgs.pkgsBuildBuild;
      selfBuildHost = otherSpliceFn pkgs.pkgsBuildHost;
      selfBuildTarget = otherSpliceFn pkgs.pkgsBuildTarget;
      selfHostHost = otherSpliceFn pkgs.pkgsHostHost;
      selfHostTarget = otherSpliceFn pkgs.pkgsHostTarget;
      selfTargetTarget = lib.optionalAttrs (pkgs.pkgsTargetTarget?newScope) (otherSpliceFn pkgs.pkgsTargetTarget);
    };
}
