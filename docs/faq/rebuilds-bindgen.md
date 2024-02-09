## I see the `bindgen` crate constantly rebuilding

If you are using `rustPlatform.bindgenHook` it is worth noting that it will
[propagate `NIX_CFLAGS_COMPILE` via
`BINDGEN_EXTRA_CLANG_ARGS`](https://github.com/NixOS/nixpkgs/blob/3a73796bf2edb1dc026257da827678117ee7af57/pkgs/build-support/rust/hooks/rust-bindgen-hook.sh#L9).

In order to support reproducible builds, [this build hook will add
`-frandom-seed=...` to
`NIX_CFLAGS_COMPILE`](https://github.com/NixOS/nixpkgs/blob/c0b7a892fb042ede583bdaecbbdc804acb85eabe/pkgs/build-support/setup-hooks/reproducible-builds.sh#L6)
based on the current derivation's hash.

Since dependencies are built in a separate derivation as the main package, each
derivation essentially gets a different value for `-frandom-seed`. The `bindgen`
crate will [observe this change and rebuild
itself](https://github.com/rust-lang/rust-bindgen/blob/62859b2c6108c1c0f60d16b9ffe7544a4fbce48b/bindgen/build.rs#L20).

A workaround for this is to set `NIX_OUTPATH_USED_AS_RANDOM_SEED` to any
arbitrary 10 character string for _all derivations_ which share artifacts
together.

```nix
buildPackage {
  NIX_OUTPATH_USED_AS_RANDOM_SEED = "aaaaaaaaaa";
  # other attributes omitted
}
```
