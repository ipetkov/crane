## A git dependency fails to find a file by a relative path

Sometimes various Rust projects are written in a way where a [build script or
`include_str!` invocation](./building-with-non-rust-includes.md) attempts to
read files outside of the crate's root, but this causes problems if such a
project is used as a git-dependency.

Normally when cargo downloads a package source from a registry like crates.io,
it extracts each crate into its own separate directory (even if the upstream
source is a workspace with multiple crates). This means that published crates
usually do not suffer from this situation, however, cargo handles git
dependencies in a different (i.e. inconsistent) manner: cargo will download the
entire git directory _but keep all files in place_, which means that those
crates _happen_ to be able to rely on a file structure which matches the
upstream repo.

Crane implements source fetching by following the behavior of the `cargo vendor`
command: each crate (whether it comes from a registry or a git repo) is extracted
in a separate directory. Thus the problem of trying to locate files outside of
the crate's (not the _workspace's_) root directory can also be demonstrated by
calling `cargo vendor` and then following its instructions (normally copying
some configuration to `.cargo/config.toml`) and then building as normal.

If building like this after running `cargo vendor` **succeeds but fails when
building with Crane** please open an issue with a reproduction! However, if the
**build fails even without Crane** there are a few options to remedying the
problem:

* Consider reporting the situation to the upstream project and/or contributing a
  change there. If the primary authors are not familiar with or users of either
  Nix or Crane, consider explaining that their project cannot be used by anyone
  who wants to vendor their sources (e.g. through using `cargo vendor`).
* Consider forking the crate and remedying the problem there until it is
  accepted upstream
* Consider [locally patching the dependency source while building with
  Nix](../patching_dependency_sources.md)
