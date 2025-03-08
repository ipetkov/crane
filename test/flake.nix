{
  nixConfig = {
    extra-substituters = [ "https://crane.cachix.org" ];
    extra-trusted-public-keys = [ "crane.cachix.org-1:8Scfpmn9w+hGdXH/Q9tTLiYAE/2dnJYRJP7kl80GuRk=" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-latest-release.url = "github:NixOS/nixpkgs/release-24.11";

    advisory-db = {
      url = "github:rustsec/advisory-db";
      flake = false;
    };

    crane.url = "github:ipetkov/crane";

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    flake-utils.url = "github:numtide/flake-utils";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ ... }: inputs.flake-utils.lib.eachDefaultSystem (system:
    let
      mkLib = pkgs: import ../default.nix {
        inherit pkgs;
      };
      nixpkgs = inputs.nixpkgs;
      pkgs = import nixpkgs {
        inherit system;
      };

      pkgsChecks = import nixpkgs {
        inherit system;
        overlays = [
          (import inputs.rust-overlay)
        ];
      };
      fenix = import inputs.fenix {
        inherit system;
      };
    in
    {
      checks = pkgsChecks.callPackages ../checks {
        pkgs = pkgsChecks;
        myLib = mkLib pkgsChecks;
        myLibCross = mkLib (import nixpkgs {
          localSystem = system;
          crossSystem = "wasm32-wasi";
        });
        myLibFenix = (mkLib pkgs).overrideToolchain (fenix.latest.withComponents [
          "cargo"
          "rust-src"
          "rustc"
        ]);
      };
    });
}
