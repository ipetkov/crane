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

    cargoFmt = myLib.cargoFmt {
      src = ./simple;
    };

    cargoTarpaulin = myLib.cargoTarpaulin {
      src = ./simple;
    };

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
          doInstallCargoArtifacts = false;
          CARGO_TARGET_DIR = "some/nested/custom-cargo-dir";
        });
      in
      pkgs.runCommandLocal "smoke-simple" { } ''
        # does it run?
        ${simple}/bin/simple
        touch $out
      '';

    depsOnlyVariousTargets = myLib.buildDepsOnly {
      src = ./various-targets;
    };

    features = callPackage ./features { };

    illegalBin = myLib.buildPackage {
      pname = "illegalBin";
      version = "0.0.1";
      src = ./illegal-bin;
    };

    manyLibs = myLib.buildPackage {
      src = ./with-libs;
      pname = "my-libs";
      version = "0.0.1";
      cargoArtifacts = null;
    };

    manyLibsInstalledAsExpected = pkgs.runCommandLocal "manyLibsInstalledAsExpected" { } ''
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

    # Test building a real world example
    ripgrep = myLib.buildPackage {
      inherit (pkgs.ripgrep) pname src version;
    };

    smoke = callPackage ./smoke.nix { };
    smokeSimple = self.smoke [ "simple" ] self.simple;
    smokeAltRegistry = self.smoke [ "alt-registry" ] (
      let
        myLibWithRegistry = myLib.appendCrateRegistries [
          (myLib.registryFromGitIndex {
            indexUrl = "https://github.com/Hirevo/alexandrie-index";
            rev = "90df25daf291d402d1ded8c32c23d5e1498c6725";
          })
        ];
      in
      myLibWithRegistry.buildPackage {
        src = ../examples/alt-registry;
        nativeBuildInputs = with pkgs; [
          pkgconfig
          openssl
        ];
      }
    );

    smokeOverlappingTargets = self.smoke [ "foo" "bar" "baz" ] (myLib.buildPackage {
      src = ./overlapping-targets;
    });

    smokeManuallyVendored = self.smoke [ "manually-vendored" ] (myLib.buildPackage {
      src = ./manually-vendored;
      cargoVendorDir = ./manually-vendored/vendor;
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
