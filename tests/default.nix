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
    cmpCleanCargoToml = callPackage ./cleanCargoToml { };
    cmpCleanCargoTomlSimple = self.cmpCleanCargoToml ./cleanCargoToml/barebones;
    cmpCleanCargoTomlComplex = self.cmpCleanCargoToml ./cleanCargoToml/complex;

    compilesFresh = callPackage ./compilesFresh.nix { };
    compilesFreshSimple = self.compilesFresh ./simple "simple";
    compilesFreshOverlappingTargets = self.compilesFresh
      ./overlapping-targets
      (builtins.concatStringsSep "\n" [
        "bar"
        "baz"
        "foo"
        "overlapping-targets"
      ]);

    customCargoTargetDirectory =
      let
        simple = self.simple.overrideAttrs (old: {
          name = "customCargoTargetDirectory";
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

    simple = myLib.buildWithCargo {
      doCopyTargetToOutput = false;
      src = ./simple;
    };

    smokeSimple = pkgs.runCommand "smoke-simple" { } ''
      # does it run?
      ${self.simple}/bin/simple
      touch $out
    '';

    smokeOverlappingTargets =
      let
        overlappingTargets = myLib.buildWithCargo {
          doCopyTargetToOutput = false;
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
