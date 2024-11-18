{
  inputs = {
    # NB: nixpkgs-unstable testing will come from the root flake
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-latest-release.url = "github:NixOS/nixpkgs/release-24.05";

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

  outputs = _: { };
}
