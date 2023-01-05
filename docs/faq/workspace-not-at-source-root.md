## Cargo workspace root (Cargo.toml) is not at the root of the derivation's source

Most cargo projects have their `Cargo.toml` at the root of the source, but it's
still possible to build a project where the `Cargo.toml` file is nested in a
deeper directory:

```nix
# Assuming that we have the following directory structure:
# ./flake.nix
# ./flake.lock
# ./nested
# ./nested/Cargo.toml
# ./nested/Cargo.lock
# ./nested/src/*.rs
craneLib.buildPackage {
 src = myLib.cleanCargoSource ./.;
 sourceRoot = "source/nested"; # Needs to start with "source/" by default
 cargoLock = ./nested/Cargo.lock;
 cargoToml = ./nested/Cargo.toml;
}
```
