{
  description = "Build a cargo project which uses SQLx";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, crane, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        inherit (pkgs) lib;

        craneLib = crane.lib.${system};

        sqlFilter = path: _type: null != builtins.match ".*sql$" path;
        sqlOrCargo = path: type: (sqlFilter path type) || (craneLib.filterCargoSources path type);

        src = lib.cleanSourceWith {
          src = craneLib.path ./.; # The original, unfiltered source
          filter = sqlOrCargo;
        };
        srcMigrations = craneLib.path ./migrations;

        # Common arguments can be set here to avoid repeating them later
        commonArgs = {
          inherit src;
          strictDeps = true;

          nativeBuildInputs = [
            pkgs.pkg-config
          ];

          buildInputs = [
            # Add additional build inputs here
            pkgs.openssl
          ] ++ lib.optionals pkgs.stdenv.isDarwin [
            # Additional darwin specific inputs can be set here
            pkgs.libiconv
          ];

          # Additional environment variables can be set directly
          # MY_CUSTOM_VAR = "some value";
        };

        # Build *just* the cargo dependencies, so we can reuse
        # all of that work (e.g. via cachix) when running in CI
        cargoArtifacts = craneLib.buildDepsOnly commonArgs;

        # Prepare a db with all of our migrations using only the migrations files
        sqlx-db = pkgs.runCommand "sqlx-db-prepare"
          {
            nativeBuildInputs = [
              pkgs.sqlx-cli
            ];
          } ''
          mkdir $out
          export DATABASE_URL=sqlite:$out/db.sqlite3
          sqlx database create
          sqlx migrate run --source ${srcMigrations}
        '';

        # Build the actual crate itself, reusing the dependency
        # artifacts from above.
        my-crate = craneLib.buildPackage (commonArgs // {
          inherit cargoArtifacts;

          preBuildPhases = [ "linkDb" ];

          nativeBuildInputs = (commonArgs.nativeBuildInputs or [ ]) ++ [
            pkgs.sqlite
          ];

          # Copy over the db so it's available for sqlx to check it's schema
          linkDb = ''
            mkdir -p db
            cp --no-preserve=ownership,mode -t ./db ${sqlx-db}/db.sqlite3*
            export DATABASE_URL=sqlite:./db/db.sqlite3
          '';
        });
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
      });
}
