{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    crane.url = "github:ipetkov/crane";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, crane, ... }: flake-utils.lib.eachDefaultSystem
    (system: {
      packages.cargo-git = (crane.mkLib nixpkgs.legacyPackages.${system}).downloadCargoPackageFromGit {
        git = "https://github.com/rust-lang/cargo";
        rev = "17f8088d6eafd82349630a8de8cc6efe03abf5fb";
      };
    });
}
