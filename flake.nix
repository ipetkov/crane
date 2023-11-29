{
  description = "A Nix library for building cargo projects. Never build twice thanks to incremental artifact caching.";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  nixConfig = {
    extra-substituters = [ "https://crane.cachix.org" ];
    extra-trusted-public-keys = [ "crane.cachix.org-1:8Scfpmn9w+hGdXH/Q9tTLiYAE/2dnJYRJP7kl80GuRk=" ];
  };

  outputs = { nixpkgs, ... }:
    let
      mkLib = pkgs: import ./lib {
        inherit (pkgs) lib newScope;
      };

      nodes = (builtins.fromJSON (builtins.readFile ./test/flake.lock)).nodes;
      inputFromLock = name:
        let
          locked = nodes.${name}.locked;
        in
        fetchTarball {
          url = "https://github.com/${locked.owner}/${locked.repo}/archive/${locked.rev}.tar.gz";
          sha256 = locked.narHash;
        };

      eachSystem = systems: f:
        let
          # Merge together the outputs for all systems.
          op = attrs: system:
            let
              ret = f system;
              op = attrs: key: attrs //
                {
                  ${key} = (attrs.${key} or { })
                    // { ${system} = ret.${key}; };
                }
              ;
            in
            builtins.foldl' op attrs (builtins.attrNames ret);
        in
        builtins.foldl' op { } systems;

      eachDefaultSystem = eachSystem [
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
      ];
    in
    {
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

        end-to-end-testing = {
          description = "Run End-to-End tests for a webapp";
          path = ./examples/end-to-end-testing;
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

        sqlx = {
          description = "Build a cargo project which uses SQLx";
          path = ./examples/sqlx;
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
    } // eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

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
                (import (inputFromLock "rust-overlay"))
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
            nix-eval-jobs
            nixpkgs-fmt
          ];
        };
      });
}
