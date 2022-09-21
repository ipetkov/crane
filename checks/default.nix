{ pkgs, myLib, myPkgs }:

let
  inherit (pkgs) lib;
  onlyDrvs = lib.filterAttrs (_: lib.isDerivation);
in
onlyDrvs (lib.makeScope myLib.newScope (self:
let
  callPackage = self.newScope { };
  x64Linux = pkgs.hostPlatform.system == "x86_64-linux";
in
myPkgs // {
  cleanCargoTomlTests = callPackage ./cleanCargoTomlTests { };

  clippy = callPackage ./clippy { };

  cargoFmt = myLib.cargoFmt {
    src = ./simple;
  };

  # https://github.com/ipetkov/crane/issues/6
  cargoClippyThenBuild = myLib.buildPackage {
    src = ./simple;
    cargoArtifacts = myLib.cargoClippy {
      cargoArtifacts = null;
      src = ./simple;
    };
  };

  # https://github.com/ipetkov/crane/issues/6
  cargoFmtThenClippy = myLib.cargoClippy {
    src = ./simple;
    cargoArtifacts = self.cargoFmt;
  };

  cargoAuditTests = callPackage ./cargoAudit.nix { };

  # NB: explicitly using a github release (not crates.io release)
  # which lacks a Cargo.lock file, so we can test adding our own
  cargoLockOverride = myLib.buildPackage rec {
    pname = "cargo-llvm-cov";
    version = "0.4.14";

    src = pkgs.fetchFromGitHub {
      owner = "taiki-e";
      repo = pname;
      rev = "v${version}";
      sha256 = "sha256-sNwizxYVUNyv5InR8HS+CyUsroA79h/FpouS+fMWJUI=";
    };

    doCheck = false; # Tests need llvm-tools installed
    cargoLock = ./testCargoLockOverride.lock;
  };

  cargoTarpaulin = lib.optionalAttrs x64Linux (myLib.cargoTarpaulin {
    src = ./simple;
  });

  compilesFresh = callPackage ./compilesFresh.nix { };
  compilesFreshSimple = self.compilesFresh "simple" (myLib.cargoBuild) {
    src = ./simple;
  };
  compilesFreshOverlappingTargets = self.compilesFresh
    (builtins.concatStringsSep "\n" [
      "bar"
      "baz"
      "foo"
      "overlapping-targets"
    ])
    myLib.cargoBuild {
      src = ./overlapping-targets;
    };

  customCargoTargetDirectory =
    let
      simple = self.simple.overrideAttrs (old: {
        pname = "customCargoTargetDirectory";
        doInstallCargoArtifacts = false;
        CARGO_TARGET_DIR = "some/nested/custom-cargo-dir";
      });
    in
    pkgs.runCommand "smoke-simple" { } ''
      # does it run?
      ${simple}/bin/simple
      touch $out
    '';

  docs = myLib.cargoDoc {
    src = ./simple;
    cargoArtifacts = myLib.buildDepsOnly {
      src = ./simple;
    };
  };
  docsFresh = self.compilesFresh "simple" (myLib.cargoDoc) {
    src = ./simple;
    cargoArtifacts = myLib.buildDepsOnly {
      src = ./simple;
    };
  };

  depsOnlyVariousTargets = myLib.buildDepsOnly {
    src = ./various-targets;
  };

  features = callPackage ./features { };

  gitOverlappingRepo = myLib.buildPackage {
    src = ./git-overlapping;
  };

  gitRevNoRef = myLib.buildPackage {
    src = ./gitRevNoRef;
  };

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

  nextest = callPackage ./nextest.nix { };

  simple = myLib.buildPackage {
    src = myLib.cleanCargoSource ./simple;
  };
  simpleGit = myLib.buildPackage {
    src = myLib.cleanCargoSource ./simple-git;
  };
  simpleCustomProfile = myLib.buildPackage {
    src = ./simple;
    CARGO_PROFILE = "test";
  };
  simpleNoProfile = myLib.buildPackage {
    src = ./simple;
    CARGO_PROFILE = "";
  };
  simpleOnlyTests = myLib.buildPackage {
    src = myLib.cleanCargoSource ./simple-only-tests;
  };
  simpleAltStdenv = myLib.buildPackage {
    src = ./simple;
    stdenv = pkgs.gcc12Stdenv;
  };
  # https://github.com/ipetkov/crane/issues/104
  simpleWithCmake = myLib.buildPackage {
    src = ./simple;
    nativeBuildInputs = with pkgs; [
      cmake
    ];
  };

  simple-nonflake = (import ../default.nix {
    inherit pkgs;
  }).buildPackage {
    src = ./simple;
  };

  removeReferencesToVendorDir = pkgs.runCommand "removeReferencesToVendorDir" { } ''
    if ${pkgs.binutils-unwrapped}/bin/strings ${self.ripgrep}/bin/rg | \
      grep --only-matching '${builtins.storeDir}/[^/]\+' | \
      grep --invert-match glibc | \
      grep --invert-match '${builtins.storeDir}/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee' --count
    then
      echo found references to /nix/store sources
      false
    else
      touch $out
    fi
  '';

  # Test building a real world example
  ripgrep = myLib.buildPackage {
    inherit (pkgs.ripgrep) pname src version;
  };

  smoke = callPackage ./smoke.nix { };
  smokeSimple = self.smoke [ "simple" ] self.simple;
  smokeSimpleGit = self.smoke [ "simple-git" ] self.simpleGit;
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

  vendorGitSubset = callPackage ./vendorGitSubset.nix { };

  workspace = myLib.buildPackage {
    src = myLib.cleanCargoSource ./workspace;
    pname = "workspace";
  };

  workspaceRoot = myLib.buildPackage {
    src = myLib.cleanCargoSource ./workspace-root;
    pname = "workspace-root";
  };

  workspaceGit = myLib.buildPackage {
    src = myLib.cleanCargoSource ./workspace-git;
    pname = "workspace-git";
  };
})
)
