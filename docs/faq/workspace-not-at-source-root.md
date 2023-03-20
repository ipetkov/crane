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
 src = myLib.cleanCargoSource (craneLib.path ./.);
 cargoLock = ./nested/Cargo.lock;
 cargoToml = ./nested/Cargo.toml;
 # Use a postUnpack hook to jump into our nested directory. This will work
 # regardless of what the unpacked source is named (i.e. will avoid hashes
 # when using the root path of a flake).
 #
 # The unpackPhase sets `$sourceRoot` to the directory that was unpacked
 # but unfortunately `postUnpack` runs before the directory is actually
 # changed so we'll do two things:
 # 1. Jump into the directory we want (replace `nested` with your directory)
 # 2. Overwrite the variable so when the default build scripts run they don't
 # end up changing to a different directory again
 postUnpack = ''
   cd $sourceRoot/nested
   sourceRoot="."
 '';
}
```
