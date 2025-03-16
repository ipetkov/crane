{ lib
, pkgs
}:
let
  nativePkgs = pkgs.pkgsBuildBuild;
  cranePrefix = "__CRANE_EXPORT_";
in
stdenvSelector:
let
  hostStdenv = stdenvSelector pkgs.pkgsBuildHost;
  targetStdenv = stdenvSelector pkgs.pkgsHostTarget;

  varsForPlatform = buildKind: stdenv:
    let
      ccPrefix = stdenv.cc.targetPrefix;
      cargoEnv = stdenv.hostPlatform.rust.cargoEnvVarTarget;
      # Configure an emulator for the platform (if we need one, and there's one available)
      runnerAvailable = !(stdenv.buildPlatform.canExecute stdenv.hostPlatform)
        && stdenv.hostPlatform.emulatorAvailable nativePkgs;
    in
    (lib.optionalAttrs runnerAvailable {
      "${cranePrefix}CARGO_TARGET_${cargoEnv}_RUNNER" = stdenv.hostPlatform.emulator nativePkgs;
    }) // {
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
lib.optionalAttrs (pkgs.stdenv.buildPlatform != pkgs.stdenv.hostPlatform) (lib.mergeAttrsList [
  {
    # Set the target we want to build for (= our host platform)
    # The configureCargoCommonVars setup hook will set CARGO_BUILD_TARGET to this value if the user hasn't specified their own target to use
    "${cranePrefix}CARGO_BUILD_TARGET" = pkgs.stdenv.hostPlatform.rust.rustcTarget;

    # Pull in any compilers we need
    nativeBuildInputs = [ hostStdenv.cc targetStdenv.cc ];
  }

  # NOTE: "host" here isn't the nixpkgs platform; it's a "build kind" corresponding to the "build" nixpkgs platform
  (varsForPlatform "HOST" hostStdenv)

  # NOTE: "target" here isn't the nixpkgs platform; it's a "build kind" corresponding to the "host" nixpkgs platform
  (varsForPlatform "TARGET" targetStdenv)
])
