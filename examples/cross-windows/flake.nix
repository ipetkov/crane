{
  description = "Cross compiling a rust program for windows";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst";

    crane.url = "github:ipetkov/crane";

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      nixpkgs,
      crane,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          localSystem = system;
          crossSystem = {
            config = "x86_64-w64-mingw32";
            libc = "msvcrt";
          };
        };

        craneLib = crane.mkLib pkgs;

        my-crate = craneLib.buildPackage {
          src = craneLib.cleanCargoSource ./.;

          strictDeps = true;
        };
      in
      {
        packages = {
          inherit my-crate;
          default = my-crate;
        };

        checks = {
          inherit my-crate;
        };
      }
    );
}
