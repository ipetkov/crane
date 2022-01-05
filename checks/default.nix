{ pkgs, myLib }:

let
  inherit (pkgs) lib;
  onlyDrvs = lib.filterAttrs (_: lib.isDerivation);
in
onlyDrvs (lib.makeScope myLib.newScope (self:
  let
    callPackage = self.newScope { };
  in
  {
    checkNixpkgsFmt = callPackage ./nixpkgs-fmt.nix { };

    cleanCargoTomlTests = callPackage ./cleanCargoToml { };

    clippy = callPackage ./clippy { };

    compilesFresh = callPackage ./compilesFresh.nix { };
    compilesFreshSimple = self.compilesFresh ./simple "simple" { };
    compilesFreshOverlappingTargets = self.compilesFresh
      ./overlapping-targets
      (builtins.concatStringsSep "\n" [
        "bar"
        "baz"
        "foo"
        "overlapping-targets"
      ])
      { };

    customCargoTargetDirectory =
      let
        simple = self.simple.overrideAttrs (old: {
          pname = "customCargoTargetDirectory";
          doCopyTargetToOutput = false;
          CARGO_TARGET_DIR = "some/nested/custom-cargo-dir";
        });
      in
      pkgs.runCommand "smoke-simple" { } ''
        # does it run?
        ${simple}/bin/simple
        touch $out
      '';

    depsOnlyVariousTargets = myLib.buildDepsOnly {
      src = ./various-targets;
    };

    features = callPackage ./features { };

    manyLibs = myLib.buildPackage {
      src = ./with-libs;
      pname = "my-libs";
      version = "0.0.1";
      cargoArtifacts = null;
    };

    manyLibsInstalledAsExpected = pkgs.runCommand "manyLibsInstalledAsExpected" { } ''
      cat >expected <<EOF
      liball_types.a
      liball_types.so
      libonly_cdylib.so
      libonly_staticlib.a
      EOF

      diff ./expected <(ls -1 ${self.manyLibs}/lib)
      touch $out
    '';

    simple = myLib.buildPackage {
      src = ./simple;
    };

    smokeSimple = pkgs.runCommand "smoke-simple" { } ''
      # does it run?
      ${self.simple}/bin/simple
      touch $out
    '';

    smokeOverlappingTargets =
      let
        overlappingTargets = myLib.buildPackage {
          src = ./overlapping-targets;
        };
      in
      pkgs.runCommand "smoke-overlapping-targets" { } ''
        # does it run?
        ${overlappingTargets}/bin/foo
        ${overlappingTargets}/bin/bar
        ${overlappingTargets}/bin/baz
        touch $out
      '';
  })
)
