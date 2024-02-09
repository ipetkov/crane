{ pkgs, myLib, myLibCross }:

let
  inherit (pkgs) lib;
  inherit (pkgs.stdenv) isDarwin;
  onlyDrvs = lib.filterAttrs (_: lib.isDerivation);
in
onlyDrvs (lib.makeScope myLib.newScope (self:
let
  callPackage = self.newScope { };
  myLibLlvmTools = myLib.overrideToolchain (pkgs.rust-bin.stable.latest.minimal.override {
    extensions = [ "llvm-tools" ];
  });
  x64Linux = pkgs.hostPlatform.system == "x86_64-linux";
  aarch64Darwin = pkgs.hostPlatform.system == "aarch64-darwin";
in
{
  # https://github.com/ipetkov/crane/issues/411
  bzip2Sys = myLib.buildPackage {
    src = ./bzip2-sys;
    strictDeps = false; # Explicitly repro original report
    installCargoArtifactsMode = "use-zstd";
    nativeBuildInputs = [ pkgs.pkg-config ];
  };

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

  cargoDenyTests = callPackage ./cargoDeny.nix { };

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

          cargoExtraArgs = "--offline";
          doCheck = false; # Tests need llvm-tools installed
          buildInputs = lib.optionals isDarwin [
            pkgs.libiconv
          ];
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

  # https://github.com/ipetkov/crane/issues/356
  cargoTarpaulinAfterClippy = lib.optionalAttrs x64Linux (myLib.cargoTarpaulin {
    src = ./simple;
    cargoArtifacts = myLib.cargoClippy {
      src = ./simple;
      cargoArtifacts = myLib.buildDepsOnly {
        src = ./simple;
      };
    };
  });

  chainedMultiple = pkgs.linkFarmFromDrvs "chainedMultiple" (map
    (test:
      let
        args = test // {
          src = ./simple;
          RUSTC_WRAPPER = pkgs.callPackage ./rustc-wrapper.nix { };
        };
      in
      myLib.cargoBuild (args // {
        __CRANE_DENY_COMPILATION = true;

        cargoArtifacts = myLib.cargoBuild (args // {
          cargoArtifacts = myLib.cargoClippy (args // {
            cargoArtifacts = myLib.buildDepsOnly args;
          });
        });
      })
    )
    [
      { }
      { installCargoArtifactsMode = "use-zstd"; }
      { installCargoArtifactsMode = "use-symlink"; }
    ]
  );

  # https://github.com/ipetkov/crane/issues/417
  codesign = lib.optionalAttrs aarch64Darwin (
    let
      codesignPackage = myLib.buildPackage {
        src = ./codesign;
        strictDeps = true;
        nativeBuildInputs = [ pkgs.pkg-config pkgs.libiconv ];
        buildInputs = [ pkgs.openssl ];
        dontStrip = true;
      };
    in
    pkgs.runCommand "codesign" { } "${codesignPackage}/bin/codesign > $out"
  );

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
  compilesFreshWorkspace = self.compilesFresh
    {
      check = (builtins.concatStringsSep "\n" [
        "hello"
        "print"
        "world"
      ]);
      build = (builtins.concatStringsSep "\n" [
        "hello"
        "print"
        "world"
      ]);
    }
    myLib.cargoBuild
    {
      src = ./workspace;
    };

  craneUtilsChecks =
    let
      src = myLib.cleanCargoSource ../pkgs/crane-utils;
      cargoArtifacts = myLib.buildDepsOnly {
        inherit src;
      };
    in
    pkgs.linkFarmFromDrvs "craneUtilsTests" [
      (myLib.cargoClippy {
        inherit cargoArtifacts src;
        cargoClippyExtraArgs = "--all-targets -- --deny warnings";
      })

      (myLib.cargoFmt {
        inherit src;
      })
    ];

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
      buildInputs = lib.optionals isDarwin [
        pkgs.libiconv
      ];
    };
    buildInputs = lib.optionals isDarwin [
      pkgs.libiconv
    ];
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
    buildInputs = lib.optionals isDarwin [
      pkgs.libiconv
    ];
  };

  depsOnlyVariousTargets = myLib.buildDepsOnly {
    src = ./various-targets;
  };

  depsOnlyCargoDoc = myLib.buildDepsOnly {
    src = ./workspace;
    version = "0.0.1";
    pname = "workspace";
    buildPhaseCargoCommand = "cargo doc --workspace";
  };

  devShell = myLib.devShell {
    checks = {
      simple = myLib.buildPackage {
        src = ./simple;
      };
    };
  };

  # https://github.com/ipetkov/crane/issues/500
  dummyNoWarnings = myLib.buildDepsOnly {
    src = myLib.cleanCargoSource ./simple;
    pname = "dummy-no-warnings";
    version = "0.0.1";
    env.RUSTFLAGS = "--deny warnings";
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

  manyLibsInstalledAsExpected =
    let
      ext = if isDarwin then "dylib" else "so";
    in
    pkgs.runCommand "manyLibsInstalledAsExpected" { } ''
      cat >expected <<EOF
      liball_types.a
      liball_types.${ext}
      libonly_cdylib.${ext}
      libonly_dylib.${ext}
      libonly_staticlib.a
      EOF

      diff ./expected <(ls -1 ${self.manyLibs}/lib)
      touch $out
    '';

  mkDummySrcTests = callPackage ./mkDummySrcTests { };

  # https://github.com/ipetkov/crane/issues/111
  mkDummySrcCustom =
    let
      src = ./custom-dummy;
      dotCargoOnly = lib.cleanSourceWith {
        inherit src;
        # Only keep `*/.cargo/*`
        filter = path: _type: lib.hasInfix ".cargo" path;
      };
    in
    myLib.buildPackage {
      src = ./custom-dummy;
      extraDummyScript = ''
        cp -r ${dotCargoOnly} -T $out/
      '';
    };

  multiOutputDerivation = myLib.buildPackage {
    src = ./simple;
    outputs = [ "out" "doc" ];
    preInstall = ''
      echo "Very useful documentation" > "$doc"
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

  procMacro = myLib.buildPackage {
    src = myLib.cleanCargoSource ./proc-macro;
  };

  simple = myLib.buildPackage {
    src = myLib.cleanCargoSource ./simple;
  };

  simpleWithLockOverride = myLib.buildPackage {
    cargoVendorDir = myLib.vendorCargoDeps { src = ./simple; };
    src = lib.cleanSourceWith {
      src = ./simple;
      # Intentionally filter out Cargo.lock
      filter = path: _type: !(lib.hasSuffix "Cargo.lock" path);
    };

    cargoLock = ./simple/Cargo.lock;
  };

  simpleGit = myLib.buildPackage {
    src = myLib.cleanCargoSource ./simple-git;
    buildInputs = lib.optionals isDarwin [
      pkgs.libiconv
    ];
  };
  simpleGitWithHashes = myLib.buildPackage {
    src = myLib.cleanCargoSource ./simple-git;
    outputHashes = {
      "git+https://github.com/BurntSushi/byteorder.git#2e17045ca2580719b2df78973901b56eb8a86f49" = "sha256-YgwtCY93fzrCrLJgrYBHJOwecD1dcVOo/ZS7hh+LcgA=";
      "git+https://github.com/dtolnay/rustversion.git?rev=2abd4d0e00db08bb91145cb88e5dcbad2f45bbcb#2abd4d0e00db08bb91145cb88e5dcbad2f45bbcb" = "sha256-deS6eoNuWPZ1V3XO9UzR07vLHZjT9arAYL0xEJCoU6E=";
      "git+https://github.com/rust-lang/libc.git?branch=main#40741baa1d892518fd3c39795e962058ff558fb9" = "sha256-vg/KRYC3NPM3J+RY/SU3vqQr/JbJkQ7VPu97IxIhZRk=";
      "git+https://github.com/seanmonstar/num_cpus.git?tag=v1.13.1#5f1b03332000b4c4274b5bd35fac516049ff1c6b" = "sha256-mNMxS/WXjNokO9mFXQSwyuIpIp/n94EQ9Ni0Bl40es8=";
    };
    buildInputs = lib.optionals isDarwin [
      pkgs.libiconv
    ];
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
        buildInputs = lib.optionals isDarwin [
          pkgs.libiconv
        ];
      };

      extraAllowed = builtins.concatStringsSep "\\|" (lib.optionals isDarwin [
        ""
        "libiconv"
        "libcxx"
        "apple-framework-CoreFoundation"
      ]);
    in
    pkgs.runCommand "removeReferencesToVendorDir"
      {
        nativeBuildInputs = [ pkgs.binutils-unwrapped ];
      } ''
      if strings ${crate}/bin/grpcio-test | \
        grep --only-matching '${builtins.storeDir}/[^/]\+' | \
        grep --invert-match 'glibc\|gcc${extraAllowed}' | \
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
    buildInputs = lib.optionals isDarwin [
      pkgs.libiconv
    ];
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
        (myLib.registryFromSparse {
          indexUrl = "https://index.crates.io";
          configSha256 = "d16740883624df970adac38c70e35cf077a2a105faa3862f8f99a65da96b14a3";
        })
      ];
    in
    myLibWithRegistry.buildPackage {
      src = ../examples/alt-registry;
      strictDeps = true;
      nativeBuildInputs = [
        pkgs.pkg-config
      ];
      buildInputs = [
        pkgs.openssl
      ] ++ lib.optionals isDarwin [
        pkgs.libiconv
        pkgs.darwin.apple_sdk.frameworks.Security
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

  trunk = callPackage ./trunk.nix {
    inherit myLib;
  };

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

  vendorIsCrossAgnostic =
    let
      mkVendor = whichLib: builtins.unsafeDiscardStringContext (
        (whichLib.vendorCargoDeps {
          src = ./simple-git;
        }).drvPath
      );
      expected = mkVendor myLib;
      actual = mkVendor myLibCross;
    in
    pkgs.runCommand "vendorIsCrossAgnostic" { } ''
      if [[ "${expected}" == "${actual}" ]]; then
        touch $out
      else
        echo derivations differ. to debug run:
        echo 'nix run nixpkgs#nix-diff -- "${expected}" "${actual}"'
        exit 1
      fi
    '';

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
        buildInputs = lib.optionals isDarwin [
          pkgs.libiconv
        ];
      })
      (myLib.buildPackage {
        inherit cargoVendorDir;
        src = myLib.cleanCargoSource ./simple-git-workspace-inheritance;
        buildInputs = lib.optionals isDarwin [
          pkgs.libiconv
        ];
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

  zstdNoChange =
    let
      args = {
        installCargoArtifactsMode = "use-zstd";
        zstdCompressionExtraArgs = "-19";
        src = ./simple;
      };
    in
    myLib.cargoBuild (args // {
      cargoArtifacts = myLib.cargoBuild (args // {
        cargoArtifacts = myLib.buildDepsOnly args;
      });
    });
})
)
