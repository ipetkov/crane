## How can I build only a subset of a given cargo workspace?

By default, cargo will build the crate at the current directory when invoked; if
the current directory holds a workspace, cargo will then build all crates within
that workspace.

Sometimes it can be useful to only build a subset of a given workspace (e.g.
only specific binaries are needed, or some crates cannot be built for certain
platforms, etc.), and cargo [can be instructed to do so](https://doc.rust-lang.org/cargo/commands/cargo-build.html).

Notably, it is possible to set:
* `cargoExtraArgs = "-p foo -p bar";` to only build the `foo` and `bar` crates
  only, but nothing else in the workspace
* `cargoExtraArgs = "--bin baz";` to only build the `baz` binary (from whatever
  crate defines it)
* `cargoExtraArgs = "--workspace --exclude qux";` to build the entire cargo
  workspace _except for the `qux` crate_.

Consider setting `pname = "NAME_OF_THE_EXECUTABLE";` when building a single
executable from the workspace. Having the name of the package match the
executable name will allow the result to easily run via `nix run` without
further configuration.
