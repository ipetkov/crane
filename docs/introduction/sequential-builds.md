### Example Two: Sequential Builds

Let's take an alternative approach to the previous example. Suppose instead that we
care more about not wasting any resources building certain tests (even if they
would succeed!) if another particular check fails. Perhaps binary substitutes are
readily available so that we do not mind if anyone building from source is bound
by our rules, and we can be sure that all tests have passed as part of the
build.

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    crane.url = "github:ipetkov/crane";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, crane, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        craneLib = crane.mkLib pkgs;

        # Common derivation arguments used for all builds
        commonArgs = {
          src = craneLib.cleanCargoSource ./.;
          strictDeps = true;

          buildInputs = with pkgs; [
            # Add extra build inputs here, etc.
            # openssl
          ];

          nativeBuildInputs = with pkgs; [
            # Add extra native build inputs here, etc.
            # pkg-config
          ];
        };

        # Build *just* the cargo dependencies, so we can reuse
        # all of that work (e.g. via cachix) when running in CI
        cargoArtifacts = craneLib.buildDepsOnly (commonArgs // {
          # Additional arguments specific to this derivation can be added here.
          # Be warned that using `//` will not do a deep copy of nested
          # structures
          pname = "mycrate-deps";
        });

        # First, run clippy (and deny all warnings) on the crate source.
        myCrateClippy = craneLib.cargoClippy (commonArgs // {
          # Again we apply some extra arguments only to this derivation
          # and not every where else. In this case we add some clippy flags
          inherit cargoArtifacts;
          cargoClippyExtraArgs = "--all-targets -- --deny warnings";
        });

        # Next, we want to run the tests and collect code-coverage, _but only if
        # the clippy checks pass_ so we do not waste any extra cycles.
        myCrateCoverage = craneLib.cargoTarpaulin (commonArgs // {
          cargoArtifacts = myCrateClippy;
        });

        # Build the actual crate itself, _but only if the previous tests pass_.
        myCrate = craneLib.buildPackage (commonArgs // {
          cargoArtifacts = myCrateCoverage;
        });
      in
      {
        packages.default = myCrate;
        checks = {
         inherit
           # Build the crate as part of `nix flake check` for convenience
           myCrate
           myCrateCoverage;
        };
      });
}
```

When we run `nix flake check` the following will happen:
1. The sources for any dependency crates will be fetched
1. They will be built without our crate's code and the artifacts propagated
1. Next the clippy checks will run, reusing the dependency artifacts above.
1. Next the code coverage tests will run, reusing the artifacts from the clippy
   run
1. Finally the actual crate itself is built

In this case we lose the ability to build derivations independently, but we gain
the ability to enforce a strict build order. However, we can easily change our
mind, which would be much more difficult if we had written everything as one
giant derivation.
