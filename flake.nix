{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils = {
      url = "github:numtide/flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, utils, ... }: utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        inherit system;
      };

      lib = import ./lib {
        inherit pkgs;
      };

      checks = import ./checks {
        inherit pkgs;
      };
    in
    {
      inherit checks lib;

      devShell = pkgs.mkShell {
        inputsFrom = builtins.attrValues checks;
      };
    });
}
