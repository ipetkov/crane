{
  description = "Cross compiling a rust program using rust-overlay";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    crane.url = "github:ipetkov/crane";

    flake-utils.url = "github:numtide/flake-utils";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, crane, flake-utils, rust-overlay, ... }:
    flake-utils.lib.eachDefaultSystem (localSystem:
      let
        # Replace with the system you want to build for
        crossSystem = "aarch64-linux";

        pkgs = import nixpkgs {
          inherit crossSystem localSystem;
          overlays = [ (import rust-overlay) ];
        };

        craneLib = (crane.mkLib pkgs).overrideToolchain (p: p.rust-bin.stable.latest.default);

        # Note: we have to use the `callPackage` approach here so that Nix
        # can "splice" the packages in such a way that dependencies are
        # compiled for the appropriate targets. If we did not do this, we
        # would have to manually specify things like
        # `nativeBuildInputs = with pkgs.pkgsBuildHost; [ someDep ];` or
        # `buildInputs = with pkgs.pkgsHostHost; [ anotherDep ];`.
        #
        # Normally you can stick this function into its own file and pass
        # its path to `callPackage`.
        crateExpression =
          { openssl
          , libiconv
          , lib
          , pkg-config
          , qemu
          , stdenv
          }:
          craneLib.buildPackage {
            src = craneLib.cleanCargoSource ./.;
            strictDeps = true;

            # Build-time tools which are target agnostic. build = host = target = your-machine.
            # Emulators should essentially also go `nativeBuildInputs`. But with some packaging issue,
            # currently it would cause some rebuild.
            # We put them here just for a workaround.
            # See: https://github.com/NixOS/nixpkgs/pull/146583
            depsBuildBuild = [
              qemu
            ];

            # Dependencies which need to be build for the current platform
            # on which we are doing the cross compilation. In this case,
            # pkg-config needs to run on the build platform so that the build
            # script can find the location of openssl. Note that we don't
            # need to specify the rustToolchain here since it was already
            # overridden above.
            nativeBuildInputs = [
              pkg-config
              stdenv.cc
            ] ++ lib.optionals stdenv.buildPlatform.isDarwin [
              libiconv
            ];

            # Dependencies which need to be built for the platform on which
            # the binary will run. In this case, we need to compile openssl
            # so that it can be linked with our executable.
            buildInputs = [
              # Add additional build inputs here
              openssl
            ];

            # Tell cargo about the linker and an optional emulater. So they can be used in `cargo build`
            # and `cargo run`.
            # Environment variables are in format `CARGO_TARGET_<UPPERCASE_UNDERSCORE_RUST_TRIPLE>_LINKER`.
            # They are also be set in `.cargo/config.toml` instead.
            # See: https://doc.rust-lang.org/cargo/reference/config.html#target
            CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER = "${stdenv.cc.targetPrefix}cc";
            CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_RUNNER = "qemu-aarch64";

            # Tell cargo which target we want to build (so it doesn't default to the build system).
            # We can either set a cargo flag explicitly with a flag or with an environment variable.
            cargoExtraArgs = "--target aarch64-unknown-linux-gnu";
            # CARGO_BUILD_TARGET = "aarch64-unknown-linux-gnu";

            # These environment variables may be necessary if any of your dependencies use a
            # build-script which invokes the `cc` crate to build some other code. The `cc` crate
            # should automatically pick up on our target-specific linker above, but this may be
            # necessary if the build script needs to compile and run some extra code on the build
            # system.
            HOST_CC = "${stdenv.cc.nativePrefix}cc";
            TARGET_CC = "${stdenv.cc.targetPrefix}cc";
          };

        # Assuming the above expression was in a file called myCrate.nix
        # this would be defined as:
        # my-crate = pkgs.callPackage ./myCrate.nix { };
        my-crate = pkgs.callPackage crateExpression { };
      in
      {
        checks = {
          inherit my-crate;
        };

        packages.default = my-crate;

        apps.default = flake-utils.lib.mkApp {
          drv = pkgs.writeScriptBin "my-app" ''
            ${pkgs.pkgsBuildBuild.qemu}/bin/qemu-aarch64 ${my-crate}/bin/cross-rust-overlay
          '';
        };
      });
}
