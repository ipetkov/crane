### Example One: Artifact Reuse

Suppose we are developing a crate and want to run our CI assurance checks
via `nix flake check`. Perhaps we want the CI gate to be very strict and block
any changes which raise warnings when run with `cargo clippy`. Oh, and we want
to enforce some code coverage too!

Except we do not want to push our strict guidelines on any downstream consumers
who may want to build our crate. Suppose they need to build the crate with a
different compiler version (for one reason or another) which comes with a new lint
whose warnings we have not yet addressed. We don't want to make their life
harder, so we want to make sure we do not run `cargo clippy` as part of the
crate's actual derivation, but at the same time, we don't want to have to
rebuild dependencies from scratch.

Here's how we can set up our flake to achieve our goals:

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

        # Run clippy (and deny all warnings) on the crate source,
        # reusing the dependency artifacts (e.g. from build scripts or
        # proc-macros) from above.
        #
        # Note that this is done as a separate derivation so it
        # does not impact building just the crate by itself.
        myCrateClippy = craneLib.cargoClippy (commonArgs // {
          # Again we apply some extra arguments only to this derivation
          # and not every where else. In this case we add some clippy flags
          inherit cargoArtifacts;
          cargoClippyExtraArgs = "--all-targets -- --deny warnings";
        });

        # Build the actual crate itself, reusing the dependency
        # artifacts from above.
        myCrate = craneLib.buildPackage (commonArgs // {
          inherit cargoArtifacts;
        });

        # Also run the crate tests under cargo-tarpaulin so that we can keep
        # track of code coverage
        myCrateCoverage = craneLib.cargoTarpaulin (commonArgs // {
          inherit cargoArtifacts;
        });
      in
      {
        packages.default = myCrate;
        checks = {
         inherit
           # Build the crate as part of `nix flake check` for convenience
           myCrate
           myCrateClippy
           myCrateCoverage;
        };
      });
}
```

When we run `nix flake check` the following will happen:
1. The sources for any dependency crates will be fetched
1. They will be built without our crate's code and the artifacts propagated
1. Our crate, the clippy checks, and code coverage collection will be built,
   each reusing the same set of artifacts from the initial source-free build. If
   enough cores are available to Nix it may build all three derivations
   completely in parallel, or schedule them in some arbitrary order.

Splitting up our builds like this also gives us the benefit of granular control
over what is rebuilt. Suppose we change our mind and decide to adjust the clippy
flags (e.g. to allow certain lints or forbid others). Doing so will _only_
rebuild the clippy derivation, without having to rebuild and rerun any of our
other tests!
