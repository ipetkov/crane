{
  description = "Cross-compile a SQLx+SQLite application for Windows";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    crane.url = "github:ipetkov/crane";

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      crane,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgsHost = nixpkgs.legacyPackages.${system};
        pkgs = pkgsHost.pkgsCross.mingwW64;

        inherit (pkgs) lib;

        craneLib = crane.mkLib pkgs;

        unfilteredRoot = ./.; # The original, unfiltered source
        src = lib.fileset.toSource {
          root = unfilteredRoot;
          fileset = lib.fileset.unions [
            # Default files from crane (Rust and cargo files)
            (craneLib.fileset.commonCargoSources unfilteredRoot)
            # Include all the .sql migrations as well
            ./migrations
          ];
        };

        # Note: we have to use the `callPackage` approach here so that Nix
        # can "splice" the packages in such a way that dependencies are
        # compiled for the appropriate targets. If we did not do this, we
        # would have to manually specify things like
        # `nativeBuildInputs = with pkgs.pkgsBuildHost; [ someDep ];` or
        # `buildInputs = with pkgs.pkgsHostHost; [ anotherDep ];`.

        # Common arguments can be set here to avoid repeating them later
        commonArgs =
          { pkg-config, zlib }:
          {
            inherit src;
            strictDeps = true;

            nativeBuildInputs = [
              # Add additional native build inputs here
              pkg-config
            ];

            buildInputs = [
              # Add additional build inputs here
              zlib
            ];

            # Additional environment variables can be set directly
            # MY_CUSTOM_VAR = "some value";
          };

        # Build *just* the cargo dependencies, so we can reuse
        # all of that work (e.g. via cachix) when running in CI
        cargoArtifacts = pkgs.callPackage (
          { pkg-config, zlib }:
          craneLib.buildDepsOnly (commonArgs {
            inherit pkg-config zlib;
          })
        ) { };

        # Build the actual crate itself, reusing the dependency
        # artifacts from above.
        my-crate = pkgs.callPackage (
          { pkg-config, zlib }:
          craneLib.buildPackage (
            (commonArgs { inherit pkg-config zlib; })
            // {
              inherit cargoArtifacts;

              nativeBuildInputs = (commonArgs.nativeBuildInputs or [ ]) ++ [
                pkgs.sqlx-cli
              ];

              preBuild = ''
                export DATABASE_URL=sqlite:./db.sqlite3
                sqlx database create
                sqlx migrate run
              '';
            }
          )
        ) { };
      in
      {
        checks = {
          # Build the crate as part of `nix flake check` for convenience
          inherit my-crate;
        };

        packages = {
          default = my-crate;
          inherit my-crate;
        };

        devShells.default = craneLib.devShell {
          # Inherit inputs from checks.
          checks = self.checks.${system};

          # Additional dev-shell environment variables can be set directly
          # MY_CUSTOM_DEVELOPMENT_VAR = "something else";

          # Extra inputs can be added here; cargo and rustc are provided by default.
          packages = [
            pkgs.sqlx-cli
          ];
        };
      }
    );
}
