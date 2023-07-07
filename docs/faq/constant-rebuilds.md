## I'm getting rebuilds all of the time, especially when I change `flake.nix`

Nix will rebuild a derivation if any of its inputs change, which includes any
file contained by the source that is passed in. For example, if the build
expression specifies `src = ./.;` then the crate will be rebuilt when _any_ file
changes (including "unrelated" changes to `flake.nix`)!

There are two main ways to avoid unnecessary builds:

1. Use a [source cleaning] function which can omit any files know to not be
   needed while building the crate (for example, all `*.nix` sources,
   `flake.lock`, and so on). For example `cleanCargoSource` (see [API docs] for
   details) implements some good defaults for ignoring irrelevant files which
   are not needed by cargo.
1. Another option is to put the crate's source files into its own subdirectory
   (e.g. `./mycrate`) and then set the build expression's source to that
   subdirectory (e.g. `src = ./mycrate;`). Then, changes to files _outside_ of
   that directory will be ignored and will not cause a rebuild

In certain (especially non-trivial) crane-based workflows, it's possible that
a change to a given file might trigger rebuilds of certain seemingly unrelated derivations.
This is most often caused by a subtle bug introducing undesired derivation inputs.

### Debugging with nix-diff
An efficient way to debug such problems is to use [`nix-diff`] to compare the derivation build plans:

```sh
# nix-diff does not support direct flake-urls so we'll need
# to get the actual derivation name
nix show-derivation .#affectedOutput | nix run nixpkgs#jq -- -r 'keys[0]' > before_drv
echo >> ./file/triggering/rebuild # cause a rebuild
nix show-derivation .#affectedOutput | nix run nixpkgs#jq -- -r 'keys[0]' > after_drv
nix run nixpkgs#nix-diff "$(cat before_drv)" "$(cat after_drv)"
```

### Debugging with just `nix`
Another way to debug such problems is to use `nix derivation show -r` to compare the derivation build plans:

```sh
nix derivation show -r .#affectedOutput > before
echo >> ./file/triggering/rebuild # cause a rebuild
nix derivation show -r .#affectedOutput > after
diff -u before after
```

The difference in the highest-level derivation should point to a direct cause of the rebuild (possibly a different lower-level input derivation which can be compared recursively).

[`nix-diff`]: https://github.com/Gabriella439/nix-diff
[source cleaning]: https://nixos.org/manual/nixpkgs/unstable/#sec-functions-library-sources

## I've used a source filter but cargo is still rebuilding all dependencies from scratch!

Another source of artifact invalidation is if
* A different set of dependency crates are being built between derivations
```nix
let
  src = ...;
in
craneLib.buildPackage {
  inherit src;

  cargoArtifacts = craneLib.buildDepsOnly {
    inherit src;
    cargoExtraArgs = "-p foo"; # Only build the `foo` crate
  };

  # Oops, we're only building the `bar` crate now
  # any dependency crates used by `bar` but not by `foo`
  # will get built from scratch!
  cargoExtraArgs = "-p bar";
}
```
* Another reason could be using different feature flags between derivations,
  which result in setting _different_ feature flags for dependency crates
  themselves and causing a rebuild
```nix
let
  src = ...;
in
craneLib.buildPackage {
  inherit src;

  cargoArtifacts = craneLib.buildDepsOnly {
    inherit src;
    cargoExtraArgs = "--no-default-features"; # Don't use any workspace features
  };

  # Oops, we're now building with an additional downstream feature flag which
  # needs to build more crates which we do not have cached!
  cargoExtraArgs = "--features feature-which-enables-downstream-feature";
}
```

If in doubt, double check that the same set of `-p`/`--package` and
`--features`/`--no-default-features`/`--all-features` flags are used between all
`buildDepsOnly`/`cargoBuild`/`cargoClippy`/`buildPackage` derivations.

### Mixing `[package]` and `[workspace]` definitions in the top-level `Cargo.toml`

Another potential pitfall is defining both `[package]` and `[workspace]` in the
project's top-level `Cargo.toml` file. Although cargo allows _both_ to be
defined, doing so results in cargo only operating on that package by default
(unless the `--workspace` flag is passed in).

Any subsequent derivations which attempt to build with `-p another-crate` might
not have their dependencies fully cached. Our recommendation is to only define
`[package]` in the top-level `Cargo.toml` if the workspace contains a single
crate; otherwise only `[workspace]` should be defined.
