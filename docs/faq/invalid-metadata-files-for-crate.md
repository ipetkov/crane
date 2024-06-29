## `found invalid metadata files for crate` errors

This error can occur when mixing components from two different Rust toolchains,
for example, using `clippy` with artifacts produced from a different cargo
version. Check the configuration for specifying the exact Rust toolchain to be
used in the build:

```nix
let
  rustToolchainForPkgs = p: ...;
  rustToolchain = rustToolchainForPkgs pkgs;
in
# Incorrect usage, missing `clippy` override!
#(crane.mkLib pkgs).overrideScope (final: prev: {
#  rustc = rustToolchain;
#  cargo = rustToolchain;
#  rustfmt = rustToolchain;
#});

# Correct usage (`overrideToolchain` handles the details for us)
(crane.mkLib pkgs).overrideToolchain rustToolchainForPkgs
```
