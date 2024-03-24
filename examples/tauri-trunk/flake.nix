{
  description = "Build a cargo project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    crane = {
      url = "path:/tmp/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
  };

  outputs = { self, nixpkgs, crane, flake-utils, rust-overlay, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
        };

        inherit (pkgs) lib;

        rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          # Set the build targets supported by the toolchain,
          # wasm32-unknown-unknown is required for trunk
          targets = [ "wasm32-unknown-unknown" ];
        };
        craneLib = (crane.mkLib pkgs).overrideToolchain rustToolchain;

        # When filtering sources, we want to allow assets other than .rs files
        src = lib.cleanSourceWith {
          src = ./.; # The original, unfiltered source
          filter = path: type:
            (lib.hasSuffix "\.html" path) ||
            (lib.hasSuffix "\.scss" path) ||
            (lib.hasSuffix "\.css" path) ||
            (lib.hasSuffix "\.json" path) ||
            (lib.hasSuffix "\.png" path) ||
            # Example of a folder for images, icons, etc
            (lib.hasInfix "/assets/" path) ||
            # Default filter from crane (allow .rs files)
            (craneLib.filterCargoSources path type)
          ;
        };

        # Common arguments can be set here to avoid repeating them later
        commonArgs = {
          inherit src;
        };

        yewArgs = commonArgs // {
          src = "${src}/yew";
          # We must force the target, otherwise cargo will attempt to use your native target
          CARGO_BUILD_TARGET = "wasm32-unknown-unknown";
        };

        tauriArgs = with pkgs; commonArgs // {
          src = "${src}/tauri";
          nativeBuildInputs = [ pkgconfig ];
          buildInputs =  [ webkitgtk gtk3 cairo gdk-pixbuf glib dbus ];
        };

        # Build *just* the cargo dependencies, so we can reuse
        # all of that work (e.g. via cachix) when running in CI
        cargoArtifacts = craneLib.buildDepsOnly (tauriArgs // {
          # You cannot run cargo test on a wasm build
          doCheck = false;
        });
        
        # Build *just* the cargo dependencies, so we can reuse
        # all of that work (e.g. via cachix) when running in CI
        cargoArtifactsWasm = craneLib.buildDepsOnly (yewArgs // {
          # You cannot run cargo test on a wasm build
          doCheck = false;
        });

        # Build the actual crate itself, reusing the dependency
        # artifacts from above.
        # This derivation is a directory you can put on a webserver.
        yew = craneLib.buildTrunkPackage (yewArgs // {
          pname = "yew";
          inherit cargoArtifactsWasm;
        });

        tauri = craneLib.buildTauriPackage (tauriArgs // {
          pname = "tauri";
          inherit cargoArtifacts;
          tauriConfigPath = ./tauri/tauri.conf.json;
          tauriDistDir = yew;
        });
      in
      {
        checks = {
          # Build the crate as part of `nix flake check` for convenience
          inherit yew tauri;

          # Run clippy (and deny all warnings) on the crate source,
          # again, reusing the dependency artifacts from above.
          #
          # Note that this is done as a separate derivation so that
          # we can block the CI if there are issues here, but not
          # prevent downstream consumers from building our crate by itself.
          yew-clippy = craneLib.cargoClippy (yewArgs // {
            inherit cargoArtifactsWasm;
            cargoClippyExtraArgs = "--all-targets -- --deny warnings";
          });
          
          tauri-clippy = craneLib.cargoClippy (tauriArgs // {
            inherit cargoArtifacts;
            cargoClippyExtraArgs = "--all-targets -- --deny warnings";
          });

          # Check formatting
          tauri-yew-fmt = craneLib.cargoFmt {
            inherit src;
          };
        };

        packages = {
          inherit tauri yew;
        };

        apps.default = flake-utils.lib.mkApp {
          drv = tauri;
        };

        devShells.default = pkgs.mkShell {
          inputsFrom = builtins.attrValues self.checks;

          # Extra inputs can be added here
          nativeBuildInputs = with pkgs; [
            cargo
            cargo-tauri
            rustc
            trunk
          ];
        };
      });
}
