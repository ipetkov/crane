{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
    crane = {
      url = "github:ipetkov/crane";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        rust-overlay.follows = "rust-overlay";
        flake-utils.follows = "flake-utils";
      };
    };
  };
  outputs = {self, nixpkgs, flake-utils, rust-overlay, crane}:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          system = "x86_64-linux";
          overlays = [(import rust-overlay)];
          pkgs = import nixpkgs {
            inherit system overlays;
          };
          inherit (pkgs) lib;
          rustToolchain = pkgs.pkgsBuildHost.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
          craneLib = (crane.mkLib pkgs).overrideToolchain rustToolchain;
          src = lib.cleanSourceWith {
            src = ./.; # The original, unfiltered source
          };
          nativeBuildInputs = with pkgs; [rustToolchain pkg-config];
          buildInputs = with pkgs; [rustToolchain];
          commonArgs = {
            inherit src buildInputs nativeBuildInputs;
          };
          cargoArtifacts = craneLib.buildDepsOnly(commonArgs // {
            cargoBuildCommand = "cargo build --locked --profile release";
            cargoExtraArgs = "--bin test-bzip2-sys";
            doCheck = false;
            pname = "test-bzip2-sys";
            installCargoArtifactsMode = "use-zstd";
          });
          binary = craneLib.buildPackage(commonArgs // {
            inherit cargoArtifacts;
            cargoBuildCommand = "cargo build --locked --profile release";
            cargoExtraArgs = "--bin test-bzip2-sys";
            doCheck = false;
            pname = "test-bzip2-sys";
          });
        in
        with pkgs;
        {
          packages = {
            inherit binary;
            default = binary;
          };
        }

      );
}
