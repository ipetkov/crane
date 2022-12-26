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

[source cleaning]: https://nixos.org/manual/nixpkgs/unstable/#sec-functions-library-sources
