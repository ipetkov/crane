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

    cleanCargoTomlTests = callPackage ./cleanCargoTomlTests { };

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

    mkDummySrcTests = callPackage ./mkDummySrcTests { };

    simple = myLib.buildPackage {
      src = ./simple;
    };

    smoke = callPackage ./smoke.nix { };
    smokeSimple = self.smoke [ "simple" ] self.simple;

    smokeOverlappingTargets = self.smoke [ "foo" "bar" "baz" ] (myLib.buildPackage {
      src = ./overlapping-targets;
    });

    smokeWorkspace = self.smoke [ "print" ] self.workspace;
    smokeWorkspaceRoot = self.smoke [ "print" ] self.workspaceRoot;

    workspace = myLib.buildPackage {
      src = ./workspace;
    };

    workspaceRoot = myLib.buildPackage {
      src = ./workspace-root;
    };
  })
)
