## I want to cross compile aws-lc-sys to windows using mingw

In its C compilation process `aws-lc-sys` tries to compile small test
binaries to check compiler features or assert that certain compiler bugs are not present.
It also uses `cmake` and `nasm`. There are pre-assembled `nasm` objects available, however,
the script that is required to use them does not work due to an unpatched shebang.

It's especially challenging to include `aws-lc-sys` as a build dependency (or even worse, 
both as build and normal dependency). When cross compiling, the environment by default
uses the cross compiler, which compiles windows binaries. This makes the test binaries
described earlier not work properly for the build-dependency build (can't properly execute
the windows binaries on linux).

To fix those issues, use the following options in your `craneLib.buildPackage` options:

```nix
{
    # Assemble from source instead of using pre-assembled objects
    AWS_LC_SYS_PREBUILT_NASM = 0;
    # Ignore compiler warnings that cause windows cross-build to fail (because of -Werror)
    CFLAGS = "-Wno-stringop-overflow -Wno-array-bounds -Wno-restrict";
    # Fix missing <pthread.h> include
    CFLAGS_x86_64-pc-windows-gnu = "-I${pkgs.windows.mingw_w64_pthreads}/include"; # fix missing <pthread.h>
    # On linux, use linux cc/cxx (default in cross compilation stdenv is mingw)
    "CC_${buildPlatformSuffix}" = "cc";
    "CXX_${buildPlatformSuffix}" = "cc";

    # Make necessary build tools available
    nativeBuildInputs = with pkgs; [
        buildPackages.nasm
        buildPackages.cmake
    ];
}
```

In the flake below, you can find all the fixes needed for cross compilation to work, in nix build
and in a dev shell. This was tested with up to date flake inputs and cargo dependencies on July 21, 2025.
You can find a full demo project [here](https://github.com/vypxl/nix-rust-windows).

```nix
{
  description = "Build a cargo project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    crane.url = "github:ipetkov/crane";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      crane,
      fenix,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          localSystem = system;
          crossSystem = {
            config = "x86_64-w64-mingw32";
            libc = "msvcrt";
          };
        };

        buildPlatformSuffix = pkgs.lib.strings.toLower pkgs.pkgsBuildHost.stdenv.hostPlatform.rust.cargoEnvVarTarget;

        toolchain =
          with fenix.packages.${system};
          combine [
            default.toolchain
            stable.rust-src
            targets.x86_64-pc-windows-gnu.latest.rust-std
          ];

        craneLib = (crane.mkLib pkgs).overrideToolchain (p: toolchain);

        src = craneLib.cleanCargoSource ./.;

        commonArgsWin = {
          inherit src;
          strictDeps = true;
          doCheck = false;

          CARGO_BUILD_TARGET = "x86_64-pc-windows-gnu";

          # fixes issues with aws-lc-sys
          AWS_LC_SYS_PREBUILT_NASM = 0; # just assemble it instead of using the prebuilt objects
          CFLAGS = "-Wno-stringop-overflow -Wno-array-bounds -Wno-restrict"; # ignore some warnings that pop up when cross compiling
          CFLAGS_x86_64-pc-windows-gnu = "-I${pkgs.windows.mingw_w64_pthreads}/include"; # fix missing <pthread.h>
          "CC_${buildPlatformSuffix}" = "cc"; # Make linux build use linux compiler (not mingw)
          "CXX_${buildPlatformSuffix}" = "cc";

          nativeBuildInputs = with pkgs; [
            buildPackages.nasm
            buildPackages.cmake
          ];
        };

        cargoArtifactsWin = craneLib.buildDepsOnly commonArgsWin;

        make-windows-crate =
          name:
          craneLib.buildPackage (
            commonArgsWin
            // {
              cargoArtifacts = cargoArtifactsWin;
              pname = name;
              cargoExtraArgs = "-p ${name}";
            }
          );
      in
      {
        packages = {
          default = make-windows-crate "yeet";
        };

        devShells.default = craneLib.devShell {
          packages = [
            pkgs.buildPackages.nasm
            pkgs.buildPackages.cmake
          ];
          buildInputs = [
            pkgs.windows.mingw_w64_pthreads
          ];

          CARGO_BUILD_TARGET = "x86_64-pc-windows-gnu";

          # fixes issues with aws-lc-sys
          AWS_LC_SYS_PREBUILT_NASM = 0;
          CFLAGS = "-Wno-stringop-overflow -Wno-array-bounds -Wno-restrict";
          "CC_${buildPlatformSuffix}" = "cc";
          "CXX_${buildPlatformSuffix}" = "cc";
        };
      }
    );
}
```

