{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-latest-release.url = "github:NixOS/nixpkgs/release-24.11";

    advisory-db = {
      url = "github:rustsec/advisory-db";
      flake = false;
    };

    crane.url = "github:ipetkov/crane";

    deadnix.url = "github:astro/deadnix";

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

  outputs = inputs@{ ... }: {
    packages.x86_64-linux.deadnix = inputs.deadnix.packages.x86_64-linux.deadnix;
  };
}
