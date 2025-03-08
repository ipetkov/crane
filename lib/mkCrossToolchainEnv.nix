{ pkgs
, lib
,
}: stdenvSelector:
let
  nativePkgs = pkgs.pkgsBuildBuild;

  hostStdenv = stdenvSelector pkgs.pkgsBuildHost;
  targetStdenv = stdenvSelector pkgs.pkgsHostTarget;

  varsForPlatform = buildKind: stdenv:
    let
      ccPrefix = stdenv.cc.targetPrefix;
      cargoEnv = stdenv.hostPlatform.rust.cargoEnvVarTarget;
    in
    {
      # Point cargo to the correct linker
      "CARGO_TARGET_${cargoEnv}_LINKER" = "${ccPrefix}cc";

      # Set environment variables for the cc crate (see https://docs.rs/cc/latest/cc/#external-configuration-via-environment-variables)
      "CC_${cargoEnv}" = "${ccPrefix}cc";
      "CXX_${cargoEnv}" = "${ccPrefix}c++";
      "AR_${cargoEnv}" = "${ccPrefix}ar";

      # Set environment variables for the cc crate again, this time using the build kind
      # In theory, this should be redundant since we already set their equivalents above, but we set them again just to be sure
      # This way other potential users of e.g. "HOST_CC" also use the correct toolchain
      "${buildKind}_CC" = "${ccPrefix}cc";
      "${buildKind}_CXX" = "${ccPrefix}c++";
      "${buildKind}_AR" = "${ccPrefix}ar";
    }
    # Configure an emulator for the platform (if we need one, and there's one available)
    // (lib.optionalAttrs (!(stdenv.buildPlatform.canExecute stdenv.hostPlatform) && stdenv.hostPlatform.emulatorAvailable nativePkgs) {
      "CARGO_TARGET_${cargoEnv}_RUNNER" = stdenv.hostPlatform.emulator nativePkgs;
    });
in
if pkgs.buildPlatform == pkgs.hostPlatform
then { }
else
  lib.mergeAttrsList [
    {
      # Set the target we want to build for (= our host platform)
      CARGO_BUILD_TARGET = pkgs.hostPlatform.rust.rustcTarget;

      # Pull in any compilers we need
      nativeBuildInputs = [ hostStdenv.cc targetStdenv.cc ];
    }

    # NOTE: "host" here isn't the nixpkgs platform; it's a "build kind" corresponding to the "build" nixpkgs platform
    (varsForPlatform "HOST" hostStdenv)

    # NOTE: "target" here isn't the nixpkgs platform; it's a "build kind" corresponding to the "host" nixpkgs platform
    (varsForPlatform "TARGET" targetStdenv)
  ]
