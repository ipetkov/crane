{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    nix-std.url = "github:chessai/nix-std";
    utils = {
      url = "github:numtide/flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, nix-std, utils, ... }:
    let
      myPkgsFor = pkgs: pkgs.callPackages ./pkgs { };

      mkLib = pkgs: import ./lib {
        inherit (nix-std.lib.serde) fromTOML toTOML;
        inherit (pkgs) lib newScope;
        myPkgs = myPkgsFor pkgs;
      };
    in
    {
      inherit mkLib;

      overlay = final: prev: myPkgsFor final;

      templates = import ./examples;
      defaultTemplate = self.templates.hello-world;
    } // utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        myPkgs = myPkgsFor pkgs;

        # To override do: lib.overrideScope' (self: super: { ... });
        lib = mkLib pkgs;

        checks = pkgs.callPackages ./checks {
          inherit pkgs;
          myLib = lib;
        };
      in
      {
        inherit checks lib;

        packages = myPkgs;

        devShell = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            nixpkgs-fmt
          ];
        };
      });
}
