{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    flake-utils.url = "github:numtide/flake-utils";
    nix-std.url = "github:chessai/nix-std";
  };

  outputs = inputs@{ self, nixpkgs, nix-std, flake-utils, ... }:
    let
      mkMyPkgs = callPackage: import ./pkgs callPackage;
      myPkgsFor = pkgs: mkMyPkgs pkgs.callPackage;

      mkLib = pkgs: import ./lib {
        inherit (nix-std.lib.serde) fromTOML toTOML;
        inherit (pkgs) lib newScope;
        inherit mkMyPkgs;
      };
    in
    {
      inherit mkLib;

      overlay = final: prev: myPkgsFor final;

      defaultTemplate = self.templates.quick-start;
      templates = {
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

        custom-toolchain = {
          description = "Build a cargo project with a custom toolchain";
          path = ./examples/custom-toolchain;
        };

        quick-start = {
          description = "Build a cargo project";
          path = ./examples/quick-start;
        };

        quick-start-simple = {
          description = "Build a cargo project without extra checks";
          path = ./examples/quick-start-simple;
        };
      };
    } // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        # To override do: lib.overrideScope' (self: super: { ... });
        lib = mkLib pkgs;
        myPkgs = myPkgsFor pkgs;

        checks = pkgs.callPackages ./checks {
          inherit pkgs myPkgs;
          myLib = lib;
        };
      in
      {
        inherit checks lib;

        packages = myPkgs;

        devShell = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            jq
            nixpkgs-fmt
          ];
        };
      });
}
