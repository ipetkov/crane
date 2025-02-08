{
  description = "A Nix library for building cargo projects. Never build twice thanks to incremental artifact caching.";

  inputs = { };

  nixConfig = {
    extra-substituters = [ "https://crane.cachix.org" ];
    extra-trusted-public-keys = [ "crane.cachix.org-1:8Scfpmn9w+hGdXH/Q9tTLiYAE/2dnJYRJP7kl80GuRk=" ];
  };

  outputs = { ... }:
    let
      mkLib = pkgs: import ./default.nix {
        inherit pkgs;
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

        build-std = {
          description = "Build a cargo project while also compiling the standard library";
          path = ./examples/build-std;
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

        quick-start-workspace = {
          description = "Build a cargo workspace with hakari";
          path = ./examples/quick-start-workspace;
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
        nixpkgs = inputFromLock "nixpkgs";
        pkgs = import nixpkgs {
          inherit system;
        };

        myLib = mkLib pkgs;
      in
      {
        checks = { };

        packages = import ./pkgs {
          inherit pkgs myLib;
        };

        formatter = pkgs.nixpkgs-fmt;

        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            deadnix
            jq
            mdbook
            nix-eval-jobs
            nixpkgs-fmt
            taplo
          ];
        };
      });
}
