{ pkgs, myLib, myPkgs }:

let
  inherit (pkgs) lib;
  onlyDrvs = lib.filterAttrs (_: lib.isDerivation);
in
onlyDrvs (lib.makeScope myLib.newScope (self:
let
  callPackage = self.newScope { };
  myLibLlvmTools = myLib.overrideToolchain (pkgs.rust-bin.stable.latest.minimal.override {
    extensions = [ "llvm-tools" ];
  });
  x64Linux = pkgs.hostPlatform.system == "x86_64-linux";
in
{
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

  cargoLlvmCov = myLibLlvmTools.cargoLlvmCov {
    src = ./simple;
    cargoArtifacts = myLib.buildDepsOnly {
      src = ./simple;
    };
  };

  cargoLlvmCovNextest = myLibLlvmTools.cargoLlvmCov {
    src = ./simple;
    cargoLlvmCovCommand = "nextest";
    cargoArtifacts = myLib.buildDepsOnly {
      src = ./simple;
    };
    nativeBuildInputs = [ pkgs.cargo-nextest ];
  };

  # NB: explicitly using a github release (not crates.io release)
  # which lacks a Cargo.lock file, so we can test adding our own
  cargoLockOverride =
    let
      cargoLock = ./testCargoLockOverride.lock;
      cargoLockContents = builtins.readFile cargoLock;
      cargoLockParsed = builtins.fromTOML cargoLockContents;
    in
    pkgs.linkFarmFromDrvs "cargoLockOverride-tests" (map
      (args:
        myLib.buildPackage (args // rec {
          pname = "cargo-llvm-cov";
          version = "0.4.14";

          src = pkgs.fetchFromGitHub {
            owner = "taiki-e";
            repo = pname;
            rev = "v${version}";
            sha256 = "sha256-sNwizxYVUNyv5InR8HS+CyUsroA79h/FpouS+fMWJUI=";
          };

          doCheck = false; # Tests need llvm-tools installed
        }))
      [
        { inherit cargoLock; }
        { inherit cargoLockContents; }
        { inherit cargoLockParsed; }
      ]
    );

  cargoTarpaulin = lib.optionalAttrs x64Linux (myLib.cargoTarpaulin {
    src = ./simple;
    cargoArtifacts = myLib.buildDepsOnly {
      src = ./simple;
    };
  });

  compilesFresh = callPackage ./compilesFresh.nix { };
  compilesFreshSimple = self.compilesFresh "simple" (myLib.cargoBuild) {
    src = ./simple;
  };
  compilesFreshSimpleBuildPackage = self.compilesFresh "simple" (myLib.buildPackage) {
    src = ./simple;
  };
  compilesFreshOverlappingTargets = self.compilesFresh
    (builtins.concatStringsSep "\n" [
      "bar"
      "baz"
      "foo"
      "overlapping-targets"
    ])
    myLib.cargoBuild
    {
      src = ./overlapping-targets;
    };
  compilesFreshWithBuildScript = self.compilesFresh
    {
      check = (builtins.concatStringsSep "\n" [
        "build-script-build"
        "with-build-script"
      ]);
      build = (builtins.concatStringsSep "\n" [
        "with-build-script"
      ]);
      test = (builtins.concatStringsSep "\n" [
        "with-build-script"
      ]);
    }
    myLib.cargoBuild
    {
      src = ./with-build-script;
    };
  compilesFreshWithBuildScriptCustom = self.compilesFresh
    {
      check = (builtins.concatStringsSep "\n" [
        "build-script-mycustomscript"
        "with-build-script-custom"
      ]);
      build = (builtins.concatStringsSep "\n" [
        "with-build-script-custom"
      ]);
      test = (builtins.concatStringsSep "\n" [
        "with-build-script-custom"
      ]);
    }
    myLib.cargoBuild
    {
      src = ./with-build-script-custom;
    };

  customCargoTargetDirectory =
    let
      simple = self.simple.overrideAttrs (_old: {
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

  # https://github.com/ipetkov/crane/pull/234
  nonJsonCargoBuildLog =
    let
      nonJson = ''
        db_id attr "field_id" Attribute { pound_token: Pound, style: Outer, bracket_token: Bracket, path: Path { leading_colon: None, segments: [PathSegment { ident: Ident { ident: "db_id", span: #0 bytes(8250..8255) }, arguments: None }] }, tokens: TokenStream [] }
      '';
    in
    myLib.buildPackage {
      src = myLib.cleanCargoSource ./simple;
      buildPhaseCargoCommand = ''
        cargoBuildLog=$(mktemp cargoBuildLogXXXX.json)
        cargoWithProfile build --message-format json-render-diagnostics >"$cargoBuildLog"
        echo "${nonJson}" >>"$cargoBuildLog"
      '';
    };

  # https://github.com/ipetkov/crane/discussions/203
  dependencyBuildScriptPerms = myLib.cargoClippy {
    src = ./dependencyBuildScriptPerms;
    cargoExtraArgs = "--all-features --all";
    cargoClippyExtraArgs = "-- --deny warnings";
    cargoArtifacts = myLib.buildDepsOnly {
      src = ./dependencyBuildScriptPerms;
      # NB: explicitly build this with no feature flags
    };
  };

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

  # https://github.com/ipetkov/crane/issues/188
  depsOnlySourceName = myLib.buildPackage {
    src = ./highs-sys-test;
    stdenv = pkgs.clangStdenv;
    LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
    nativeBuildInputs = with pkgs; [
      cmake
    ];
  };

  depsOnlyVariousTargets = myLib.buildDepsOnly {
    src = ./various-targets;
  };

  features = callPackage ./features { };

  flakePackages =
    let
      pkgDrvs = builtins.attrValues myPkgs;
      extraChecks = lib.flatten (map builtins.attrValues
        (map (p: onlyDrvs (p.passthru.checks or { })) pkgDrvs)
      );
    in
    pkgs.linkFarmFromDrvs "flake-packages" (pkgDrvs ++ extraChecks);

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

  # https://github.com/ipetkov/crane/issues/111
  mkDummySrcCustom = myLib.buildPackage {
    src = ./custom-dummy;
    extraDummyScript = ''
      cp -r ${./custom-dummy/.cargo} -T $out/.cargo
    '';
  };

  noStd =
    let
      noStdLib = myLib.overrideToolchain (pkgs.rust-bin.stable.latest.minimal.override {
        targets = [
          "thumbv6m-none-eabi"
          "x86_64-unknown-none"
        ];
      });
    in
    lib.optionalAttrs x64Linux (noStdLib.buildPackage {
      src = noStdLib.cleanCargoSource ./no_std;
      CARGO_BUILD_TARGET = "x86_64-unknown-none";
      cargoCheckExtraArgs = "--lib --bins --examples";
      doCheck = false;
    });

  bindeps =
    let
      bindepsLib = myLib.overrideToolchain (pkgs.rust-bin.nightly.latest.minimal.override {
        targets = [
          "wasm32-unknown-unknown"
          "x86_64-unknown-none"
        ];
      });
    in
    lib.optionalAttrs x64Linux (bindepsLib.buildPackage {
      src = bindepsLib.cleanCargoSource ./bindeps;
      CARGO_BUILD_TARGET = "x86_64-unknown-none";
      cargoCheckExtraArgs = "--lib --bins --examples";
      doCheck = false;
    });

  nextest = callPackage ./nextest.nix { };

  simple = myLib.buildPackage {
    src = myLib.cleanCargoSource ./simple;
  };
  simpleGit = myLib.buildPackage {
    src = myLib.cleanCargoSource ./simple-git;
  };
  simpleGitWorkspaceInheritance = myLib.buildPackage {
    src = myLib.cleanCargoSource ./simple-git-workspace-inheritance;
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

  runCargoTests = myLib.cargoTest {
    src = ./simple;
    cargoArtifacts = myLib.buildDepsOnly {
      src = ./simple;
    };
  };

  simple-nonflake = (import ../default.nix {
    inherit pkgs;
  }).buildPackage {
    src = ./simple;
  };

  # https://github.com/ipetkov/crane/issues/119
  removeReferencesToVendorDirAndCrates =
    let
      crate = myLib.buildPackage {
        src = ./grpcio-test;
        nativeBuildInputs = [
          pkgs.cmake
        ] ++ pkgs.lib.optional pkgs.stdenv.isLinux [
          pkgs.gcc10
        ];
      };
    in
    pkgs.runCommand "removeReferencesToVendorDir"
      {
        nativeBuildInputs = [ pkgs.binutils-unwrapped ];
      } ''
      if strings ${crate}/bin/grpcio-test | \
        grep --only-matching '${builtins.storeDir}/[^/]\+' | \
        grep --invert-match 'glibc\|gcc' | \
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
  smokeSimpleGitWorkspaceInheritance = self.smoke
    [ "simple-git-workspace-inheritance" ]
    self.simpleGitWorkspaceInheritance;
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
        pkg-config
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

  vendorCargoDeps =
    let
      src = ./workspace;
      cargoLock = ./workspace/Cargo.lock;
      cargoLockContents = builtins.readFile cargoLock;
      cargoLockParsed = builtins.fromTOML cargoLockContents;
    in
    pkgs.linkFarmFromDrvs "vendorCargoDeps-tests" (map
      myLib.vendorCargoDeps
      [
        { inherit src; }
        { inherit cargoLock; }
        { inherit cargoLockContents; }
        { inherit cargoLockParsed; }
      ]
    );

  vendorGitSubset = callPackage ./vendorGitSubset.nix { };

  vendorMultipleCargoDeps =
    let
      cargoLockList = [
        ./simple-git/Cargo.lock
        ./simple-git-workspace-inheritance/Cargo.lock
      ];

      cargoLockContentsList = map builtins.readFile cargoLockList;
      cargoLockParsedList = map builtins.fromTOML cargoLockContentsList;
    in
    pkgs.linkFarmFromDrvs "vendorMultipleCargoDeps-tests" (map
      myLib.vendorMultipleCargoDeps
      [
        { inherit cargoLockList; }
        { inherit cargoLockContentsList; }
        { inherit cargoLockParsedList; }
      ]
    );

  vendorMultipleCargoDepsAndBuild =
    let
      cargoVendorDir = myLib.vendorMultipleCargoDeps {
        cargoLockList = [
          ./simple-git/Cargo.lock
          ./simple-git-workspace-inheritance/Cargo.lock
        ];
      };
    in
    pkgs.linkFarmFromDrvs "vendorMultipleCargoDepsAndBuild-tests" [
      (myLib.buildPackage {
        inherit cargoVendorDir;
        src = myLib.cleanCargoSource ./simple-git;
      })
      (myLib.buildPackage {
        inherit cargoVendorDir;
        src = myLib.cleanCargoSource ./simple-git-workspace-inheritance;
      })
    ];

  vendorMultipleCargoDepsReqwestAndStd = myLib.vendorMultipleCargoDeps {
    cargoLockList = [
      ./vendorMultiple/Cargo-lock-from-reqwest.lock
      ./vendorMultiple/Cargo-lock-from-std.lock
    ];
  };

  # https://github.com/ipetkov/crane/issues/117
  withBuildScript = myLib.buildPackage {
    src = ./with-build-script;
  };
  # https://github.com/ipetkov/crane/issues/117
  withBuildScriptCustom = myLib.buildPackage {
    src = ./with-build-script-custom;
  };

  workspace = myLib.buildPackage {
    src = myLib.cleanCargoSource ./workspace;
    pname = "workspace";
    version = "0.0.1";
  };

  workspaceHack = myLib.buildPackage {
    src = myLib.cleanCargoSource ./workspace-hack;
    pname = "workspace-hack";
    version = "0.0.1";
  };

  workspaceInheritance = myLib.buildPackage {
    src = myLib.cleanCargoSource ./workspace-inheritance;
    pname = "workspace-inheritance";
  };

  # https://github.com/ipetkov/crane/issues/209
  workspaceRootNotAtSourceRoot = myLib.buildPackage {
    pname = "workspaceRootNotAtSourceRoot";
    version = "0.0.1";
    src = myLib.cleanCargoSource ./workspace-not-at-root;
    postUnpack = ''
      cd $sourceRoot/workspace
      sourceRoot="."
    '';
    cargoLock = ./workspace-not-at-root/workspace/Cargo.lock;
    cargoToml = ./workspace-not-at-root/workspace/Cargo.toml;
  };

  workspaceRoot = myLib.buildPackage {
    src = myLib.cleanCargoSource ./workspace-root;
    pname = "workspace-root";
  };

  workspaceGit = myLib.buildPackage {
    src = myLib.cleanCargoSource ./workspace-git;
    pname = "workspace-git";
    version = "0.0.1";
  };
})
)
