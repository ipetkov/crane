## Philosophy

Crane is designed around the idea of composing cargo invocations such that they
can take advantage of the artifacts generated in previous invocations. This
allows for both flexible configurations and great caching (à la Cachix) in CI
and local development builds.

Here's how it works at a high level: when a cargo workspace is built its source
is first transformed such that only the dependencies listed by the `Cargo.toml`
and `Cargo.lock` files are built, and none of the crate's real source is
included. This allows cargo to build all dependency crates and prevents Nix from
invalidating the derivation whenever the source files are updated. Then, a
second derivation is built, this time using the real source files, which also
imports the cargo artifacts generated in the first step.

This pattern can be used with any arbitrary sequence of commands, regardless of
whether those commands are running additional lints, performing code coverage
analysis, or even generating types from a model schema. Let's take a look at two
examples at how very similar configurations can give us very different behavior!
