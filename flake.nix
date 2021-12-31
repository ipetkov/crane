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
    in
    {
      overlay = final: prev: myPkgsFor final;
    } // utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        myPkgs = myPkgsFor pkgs;

        # To override do: lib.overrideScope' (self: super: { ... });
        lib = import ./lib {
          inherit (nix-std.lib.serde) fromTOML toTOML;
          inherit (pkgs) lib newScope;
          inherit myPkgs;
        };

        checks = pkgs.callPackages ./checks {
          myLib = lib;
        };
      in
      {
        inherit checks lib;

        packages = myPkgs;

        devShell = pkgs.mkShell {
          inputsFrom = builtins.attrValues checks;
        };
      });
}
