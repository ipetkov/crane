{ lib
, linkFarmFromDrvs
, myLib
, myLibFenix
, pkgs
}:

let
  inherit (pkgs.stdenv) isDarwin;

  extraAllowed = builtins.concatStringsSep "\\|" (lib.optionals isDarwin [
    ""
    "libiconv"
    "libcxx"
    "apple-framework-CoreFoundation"
  ]);

  checkRefs = name: crate: pkgs.runCommand
    name
    {
      nativeBuildInputs = [ pkgs.binutils-unwrapped ];
    } ''
    for f in "$(find ${crate}/bin -type f)"; do
      if strings "$f" | \
        grep --only-matching '${builtins.storeDir}/[^/]\+' | \
        grep --invert-match 'glibc\|gcc${extraAllowed}' | \
        grep --invert-match '${builtins.storeDir}/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee' --count
      then
        echo found references to /nix/store sources
        false
      fi
    done
    touch $out
  '';

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
    in
    checkRefs "test_removeReferencesToRustToolchain" (myLibFatToolchain.buildPackage {
      pname = "test-scrub-toolchain";
      version = "0.1.0";
      src = ./includes-toolchain-refs;
      nativeBuildInputs = [ ] ++ pkgs.lib.optional pkgs.stdenv.isLinux [
        pkgs.gcc10
      ];
    });

  # addresses https://github.com/ipetkov/crane/issues/773
  removeReferencesToRustToolchainFenix = checkRefs "test_removeReferencesToRustToolchainFenix" (myLibFenix.buildPackage {
    pname = "test-scrub-toolchain-fenix";
    version = "0.1.0";
    src = ./includes-toolchain-refs;
    nativeBuildInputs = [ ] ++ pkgs.lib.optional pkgs.stdenv.isLinux [
      pkgs.gcc10
    ];
  });

  # https://github.com/ipetkov/crane/issues/119
  removeReferencesToVendorDirAndCrates = checkRefs "removeReferencesToVendorDir" (myLib.buildPackage {
    src = ./grpcio-test;
    nativeBuildInputs = [
      pkgs.cmake
    ] ++ pkgs.lib.optional pkgs.stdenv.isLinux [
      pkgs.gcc10
    ];
    buildInputs = lib.optionals isDarwin [
      pkgs.libiconv
    ];
  });
in
linkFarmFromDrvs "illegalReferencesTests" [
  removeReferencesToRustToolchain
  removeReferencesToRustToolchainFenix
  removeReferencesToVendorDirAndCrates
]
