## Overriding function behavior

At it's core, `crane` is instantiated via `pkgs.lib.newScope` which allows any
internal definition to be changed or replaced via `.overrideScope` (which
behaves very much like applying overlays to nixpkgs). Although this mechanism is
incredibly powerful, care should be taken to avoid creating confusing or brittle
integrations built on undocumented details.

Note that `crane`'s stability guarantees (with respect to semantic versioning) only
apply to what has been [documented at the API level](../API.md). For example,
`buildPackage` is documented to delegate to `mkCargoDerivation`, so any changes
or overrides to `mkCargoDerivation`'s behavior will be observed by
`buildPackage`. Other non-documented internal details, however, may change at
any time, so take care when reaching this deep into the internals.

Here is an example:

```nix
let
  craneLib = (inputs.crane.mkLib pkgs).overrideScope (final: prev: {
    # We override the behavior of `mkCargoDerivation` by adding a wrapper which
    # will set a default value of `CARGO_PROFILE` when not set by the caller.
    # This change will automatically be propagated to any other functions built
    # on top of it (like `buildPackage`, `cargoBuild`, etc.)
    mkCargoDerivation = args: prev.mkCargoDerivation ({
      CARGO_PROFILE = "bench"; # E.g. always build in benchmark mode unless overridden
    } // args);
  });
in
{
    # Build two different workspaces with the modified behavior above

    foo = craneLib.buildPackage {
      src = craneLib.cleanCargoSource (craneLib.path ./foo);
    };

    bar = craneLib.buildPackage {
      src = craneLib.cleanCargoSource (craneLib.path ./bar);
    };
}
```
