{
  description = "Build a cargo project with a custom toolchain";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = { self, nixpkgs, crane, flake-utils, rust-overlay, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
        };

        rustWithWasiTarget = pkgs.rust-bin.stable.latest.default.override {
          targets = [ "wasm32-wasi" ];
        };

        # NB: we don't need to overlay our custom toolchain for the *entire*
        # pkgs (which would require rebuidling anything else which uses rust).
        # Instead, we just want to update the scope that crane will use by appending
        # our specific toolchain there.
        craneLib = (crane.mkLib pkgs).overrideScope' (final: prev: {
          rustc = rustWithWasiTarget;
          cargo = rustWithWasiTarget;
          rustfmt = rustWithWasiTarget;
        });

        my-crate = craneLib.buildPackage {
          src = ./.;

          cargoExtraArgs = "--target wasm32-wasi";

          # Tests currently need to be run via `cargo wasi` which
          # isn't packaged in nixpkgs yet...
          doCheck = false;
        };
      in
      {
        checks = {
          inherit my-crate;
        };

        defaultPackage = my-crate;
        packages.my-crate = my-crate;

        apps.my-app = flake-utils.lib.mkApp {
          drv = pkgs.writeShellScriptBin "my-app" ''
            ${pkgs.wasmtime}/bin/wasmtime run ${my-crate}/bin/custom-toolchain.wasm
          '';
        };
        defaultApp = self.apps.${system}.my-app;

        devShell = pkgs.mkShell {
          inputsFrom = builtins.attrValues self.checks;

          # Extra inputs can be added here
          nativeBuildInputs = with pkgs; [
            rustWithWasiTarget
          ];
        };
      });
}
