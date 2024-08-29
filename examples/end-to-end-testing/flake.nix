{
  description = "Example E2E testing";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    crane.url = "github:ipetkov/crane";

    flake-utils.url = "github:numtide/flake-utils";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { nixpkgs, crane, flake-utils, rust-overlay, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
        };
        inherit (pkgs) lib;

        craneLib = (crane.mkLib pkgs).overrideToolchain (p: p.rust-bin.stable.latest.default);
        src = craneLib.cleanCargoSource ./.;

        workspace = craneLib.buildPackage {
          inherit src;
          doCheck = false;
          nativeBuildInputs = lib.optionals pkgs.stdenv.isDarwin
            (with pkgs.darwin.apple_sdk.frameworks; [
              pkgs.libiconv
              CoreFoundation
              Security
              SystemConfiguration
            ]);
        };

        # The script inlined for brevity, consider extracting it
        # so that it becomes independent of nix
        runE2ETests = pkgs.runCommand "e2e-tests"
          {
            nativeBuildInputs = with pkgs; [
              retry
              curl
              geckodriver
              firefox
              cacert
              postgresql
            ];
          } ''

          wait-for-connection() {
            timeout 5s \
              retry --until=success --delay "1" -- \
                curl -s "$@"
          }

          initdb postgres-data
          pg_ctl --pgdata=postgres-data --options "-c unix_socket_directories=$PWD" start
          export DATABASE_URL="postgres:///postgres?host=$PWD"
          psql "$DATABASE_URL" <<EOF
            CREATE TABLE users(name TEXT);
          EOF

          ${workspace}/bin/server &
          wait-for-connection --fail localhost:8000

          # Firefox likes to write to $HOME
          HOME="$(mktemp -d)" geckodriver &
          wait-for-connection localhost:4444

          ${workspace}/bin/e2e_tests

          touch $out
        '';

        pkgsSupportsPackage = pkg:
          (lib.elem system pkg.meta.platforms) && !(lib.elem system pkg.meta.badPlatforms);
      in
      {
        checks = {
          inherit workspace;
          # Firefox is broken in some platforms (namely "aarch64-apple-darwin"), skip those
        } // (lib.optionalAttrs (pkgsSupportsPackage pkgs.firefox) {
          inherit runE2ETests;
        });

        devShells.default = pkgs.mkShell {
          BuildInputs = with pkgs; [
            rustc
            cargo
          ] ++ (lib.optionals (!pkgs.stdenv.isDarwin) [
            geckodriver
            firefox
          ]);
        };
      });
}
