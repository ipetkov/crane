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

        lib = import ./lib {
          inherit (pkgs) lib newScope;
        };

        checks = pkgs.callPackages ./checks { };
      in
      {
        inherit checks lib;

        packages = myPkgsFor pkgs;

        devShell = pkgs.mkShell {
          inputsFrom = builtins.attrValues checks;
        };
      });
}
