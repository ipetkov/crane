{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  nixConfig = {
    extra-substituters = [ "https://crane.cachix.org" ];
    extra-trusted-public-keys = [ "crane.cachix.org-1:8Scfpmn9w+hGdXH/Q9tTLiYAE/2dnJYRJP7kl80GuRk=" ];
  };

  outputs = inputs@{ nixpkgs, flake-utils, rust-overlay, ... }:
    let
      mkLib = pkgs: import ./lib {
        inherit (pkgs) lib newScope;
      };

      nixci-configs = import ./nixci.nix {
        inherit inputs;
      };
    in
    (nixpkgs.lib.attrsets.unionOfDisjoint nixci-configs {
      inherit mkLib;

      overlays.default = _final: _prev: { };

      templates = rec {
        alt-registry = {
          description = "Build a cargo project with alternative crate registries";
          path = ./examples/alt-registry;
        };

        cross-musl = {
          description = "Building static binaries with musl";
          path = ./examples/cross-musl;
        };

        cross-rust-overlay = {
          description = "Cross compiling a rust program using rust-overlay";
          path = ./examples/cross-rust-overlay;
        };

        cross-windows = {
          description = "Cross compiling a rust program for windows";
          path = ./examples/cross-windows;
        };

        custom-toolchain = {
          description = "Build a cargo project with a custom toolchain";
          path = ./examples/custom-toolchain;
        };

        default = quick-start;
        quick-start = {
          description = "Build a cargo project";
          path = ./examples/quick-start;
        };

        quick-start-simple = {
          description = "Build a cargo project without extra checks";
          path = ./examples/quick-start-simple;
        };

        trunk = {
          description = "Build a trunk project";
          path = ./examples/trunk;
        };

        trunk-workspace = {
          description = "Build a workspace with a trunk member";
          path = ./examples/trunk-workspace;
        };
      };
    }) // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        # To override do: lib.overrideScope' (self: super: { ... });
        lib = mkLib pkgs;

        packages = import ./pkgs {
          inherit pkgs;
          myLib = lib;
        };

        checks =
          let
            pkgsChecks = import nixpkgs {
              inherit system;
              overlays = [
                rust-overlay.overlays.default
              ];
            };
          in
          pkgsChecks.callPackages ./checks {
            pkgs = pkgsChecks;
            myLib = mkLib pkgsChecks;
            myPkgs = packages;
          };
      in
      {
        inherit checks lib packages;

        formatter = pkgs.nixpkgs-fmt;

        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            jq
            mdbook
            nixpkgs-fmt
            gnused
          ] ++ (if pkgs ? nixci then [ pkgs.nixci ] else [ ]);
        };
      });
}
