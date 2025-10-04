{
  lib,
  pkgs, # Host platform is same as what Cargo build the binary for
}:
let
  inherit (pkgs) pkgsBuildBuild;

  buildPkgs = pkgs.buildPackages;
  hostPkgs = pkgs;

  cranePrefix = "__CRANE_EXPORT_";
in
stdenvSelector:
let
  varsForPlatform =
    buildKind: pkgs:
    let
      stdenv = stdenvSelector pkgs;
      ccPrefix = stdenv.cc.targetPrefix;
      cargoEnv = stdenv.hostPlatform.rust.cargoEnvVarTarget;
      # Configure an emulator for the platform (if we need one, and there's one available)
      runnerAvailable =
        !(stdenv.buildPlatform.canExecute stdenv.hostPlatform)
        && stdenv.hostPlatform.emulatorAvailable pkgsBuildBuild;
    in
    # Most non-trivial crates require this, lots of hacks are done for this.
    (lib.optionalAttrs stdenv.hostPlatform.isMinGW {
      "${cranePrefix}CARGO_TARGET_${cargoEnv}_RUSTFLAGS" =
        "-L native=${pkgs.windows.pthreads}/lib";
    })
    // (lib.optionalAttrs runnerAvailable {
      "${cranePrefix}CARGO_TARGET_${cargoEnv}_RUNNER" = stdenv.hostPlatform.emulator pkgsBuildBuild;
    })
    // {
      # Point cargo to the correct linker
      "${cranePrefix}CARGO_TARGET_${cargoEnv}_LINKER" = "${ccPrefix}cc";

      # Set environment variables for the cc crate (see https://docs.rs/cc/latest/cc/#external-configuration-via-environment-variables)
      "${cranePrefix}CC_${cargoEnv}" = "${ccPrefix}cc";
      "${cranePrefix}CXX_${cargoEnv}" = "${ccPrefix}c++";
      "${cranePrefix}AR_${cargoEnv}" = "${ccPrefix}ar";

      # Set environment variables for the cc crate again, this time using the build kind
      # In theory, this should be redundant since we already set their equivalents above, but we set them again just to be sure
      # This way other potential users of e.g. "HOST_CC" also use the correct toolchain
      "${cranePrefix}${buildKind}_CC" = "${ccPrefix}cc";
      "${cranePrefix}${buildKind}_CXX" = "${ccPrefix}c++";
      "${cranePrefix}${buildKind}_AR" = "${ccPrefix}ar";
    };
in
lib.optionalAttrs ((stdenvSelector hostPkgs).buildPlatform != (stdenvSelector hostPkgs).hostPlatform) (
  lib.mergeAttrsList [
    {
      # Set the target we want to build for (= Cargo target platform, Nixpkgs host platform)
      # The configureCargoCommonVars setup hook will set CARGO_BUILD_TARGET to this value if the user hasn't specified their own target to use
      "${cranePrefix}CARGO_BUILD_TARGET" = (stdenvSelector hostPkgs).hostPlatform.rust.rustcTarget;

      # Pull in any compilers we need
      nativeBuildInputs = [
        (stdenvSelector buildPkgs).cc
        (stdenvSelector hostPkgs).cc
      ];
    }

    # NOTE: This is Cargo's host platform (i.e. the platform Cargo runs on) and Nixpkgs's build platform.
    (varsForPlatform "HOST" buildPkgs)
    # NOTE: This is Cargo's target platform (i.e. the platform Cargo builds for) and Nixpkgs's host platform.
    (varsForPlatform "TARGET" hostPkgs)
  ]
)
