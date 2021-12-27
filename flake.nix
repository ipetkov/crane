{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils = {
      url = "github:numtide/flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, utils, ... }:
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
          inherit (pkgs) lib newScope;
          inherit myPkgs;
        };

        checks = pkgs.callPackages ./checks { };
      in
      {
        inherit checks lib;

        packages = myPkgs;

        devShell = pkgs.mkShell {
          inputsFrom = builtins.attrValues checks;
        };
      });
}
