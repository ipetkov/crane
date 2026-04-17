## Patching sources of dependency crates

Overriding the `stdenv` can be done at the "`craneLib` level" like so:

```nix
let
  craneLib = (crane.mkLib pkgs).overrideScope (final: prev: {
    # This is a function which is provided an instance of `pkgs`
    # (which may be tailored for cross compilation, DO NOT reuse
    # the `pkgs` from above`) and returns the `stdenv` instance
    # that should be used across all derivations.
    stdenvSelector = p: p.clangStdenv;
  });
in
craneLib.buildPackage {
  # etc...
}
```
