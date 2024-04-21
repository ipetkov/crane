## Overriding derivations

Sometimes it is useful for a downstream consumer of a derivation to override
portions of its behavior (such as swapping out a dependency with another
customized package, or to perhaps opt-in or opt-out of additional behavior).
There are two main techniques to achieve this defined by `nixpkgs`: using
`.override` and `.overrideAttrs`.

Neither of these are specific to `crane`, but are documented here as a general
primer.

### `.override`

The `.override` attribute comes from `makeOverridable` from `nixpkgs`, which is
automatically invoked by `callPackage`. Normally using `.override` only changes
the parameters made available to the function which prepares the derivation, _but
does not alter the derivation's attributes_ directly:

```nix
# my-crate.nix
{ craneLib
, lib
, withFoo ? true
, withBar ? false
}:

craneLib.buildPackage {
  src = craneLib.cleanCargoSource (craneLib.path ./..);
  strictDeps = true;
  cargoExtraArgs =
      (lib.optionalString withFoo "--features foo") +
      (lib.optionalString withBar "--features bar");
}
```

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
  };

  outputs = { self, nixpkgs, crane, fenix, flake-utils, advisory-db, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
        };

        craneLib = crane.mkLib pkgs;
        my-crate = pkgs.callPackage ./my-crate.nix {
          inherit craneLib;
        };
      in
      {
        packages = {
          # The default definition
          default = my-crate;

          # Ensure all additional options are enabled
          my-crate-all = my-crate.override {
            withBar = true;
          };

          # Disable all optional functionality
          my-crate-minimal = my-crate.override {
            withFoo = false;
          };

          # Use a different `craneLib` instantiation: one with a nightly compiler
          my-crate-nightly = my-crate.override {
            craneLib = craneLib.overrideToolchain pkgs.rust-bin.nightly.latest.default;
          };
        };
      });
}
```

### `.overrideAttrs`

The `.overrideAttrs` attribute comes from `mkDerivation` (which all `crane` APIs
eventually call) and it allows changing what is passed into `mkDerivation`
itself (i.e. this _does_ change derivation attributes). It is a much more low
level operation, and although it _can_ be used to achieve the same things
possible via `.override`, it may be more cumbersome to plumb the changes
through.

Note that `.overrideAttrs` _will_ ***not*** change what inputs `crane` APIs see,
as it affects the derivation produced _after_ those APIs have finished running.
If you need to change behavior that way, consider using a combination of
`callPackage` and `.override`.

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, crane, fenix, flake-utils, advisory-db, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        craneLib = crane.mkLib pkgs;
        my-crate = craneLib.buildPackage {
          src = craneLib.cleanCargoSource (craneLib.path ./.);
          strictDeps = true;
        };
      in
      {
        packages = {
          # The default definition
          default = my-crate;

          # Perform a build with debug logging enabled
          my-crate-debug = my-crate.overrideAttrs (old: {
            NIX_DEBUG = 10;
          });
        };
      });
}
```
