{
  inputs = {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/release-23.05";

    advisory-db = {
      url = "github:rustsec/advisory-db";
      flake = false;
    };

    fenix.url = "github:nix-community/fenix";

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = _: {};
}
