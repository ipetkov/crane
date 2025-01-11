{ lib
, linkFarmFromDrvs
, myLib
, myLibFenix
, pkgs
}:

let
  inherit (pkgs.stdenv) isDarwin;

  # addresses https://github.com/ipetkov/crane/issues/773
  removeReferencesToRustToolchain =
    let
      myLibFatToolchain = myLib.overrideToolchain (p: p.rust-bin.stable.latest.default.override {
        extensions = [
          "cargo"
          "rust-src"
          "rustc"
        ];
      });

      crate = myLibFatToolchain.buildPackage {
        pname = "test-scrub-toolchain";
        version = "0.1.0";
        src = ./includes-toolchain-refs;
        nativeBuildInputs = [ ] ++ pkgs.lib.optional pkgs.stdenv.isLinux [
          pkgs.gcc10
        ];
      };
    in
    pkgs.runCommand "test_removeReferencesToRustToolchain"
      {
        nativeBuildInputs = [ pkgs.binutils-unwrapped ];
      } ''
      if strings ${crate}/bin/test_crane | \
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

  # addresses https://github.com/ipetkov/crane/issues/773
  removeReferencesToRustToolchainFenix =
    let
      crate = myLibFenix.buildPackage {
        pname = "test-scrub-toolchain-fenix";
        version = "0.1.0";
        src = ./includes-toolchain-refs;
        nativeBuildInputs = [ ] ++ pkgs.lib.optional pkgs.stdenv.isLinux [
          pkgs.gcc10
        ];
      };
    in
    pkgs.runCommand "test_removeReferencesToRustToolchainFenix"
      {
        nativeBuildInputs = [ pkgs.binutils-unwrapped ];
      } ''
      if strings ${crate}/bin/test_crane | \
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
in
linkFarmFromDrvs "illegalReferencesTests" [
  removeReferencesToRustToolchain
  removeReferencesToRustToolchainFenix
  removeReferencesToVendorDirAndCrates
]
