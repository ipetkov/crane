# Crane

A [Nix] library for building [cargo] projects.

* **Source fetching**: automatically done using a Cargo.lock file
* **Incremental**: build your workspace dependencies just once, then quickly lint,
  build, and test changes to your project without slowing down
* **Composable**: split builds and tests into granular steps. Gate CI without
  burdening downstream consumers building from source.

## Features

* Automatic vendoring of dependencies in a way that works with Nix
  - Alternative cargo registries are supported (with a minor configuration
    change)
  - Git dependencies are automatically supported without additional
    configuration.
    - Cargo retains the flexibility to only use these dependencies when they are
      actually needed, without forcing an override for the entire workspace.
* Reusing dependency artifacts after only building them once
* [clippy] checks
* [rustfmt] checks
* [cargo-audit] for vulnerability scanning
* [cargo-nextest] a next-generation test runner
* [cargo-tarpaulin] for code coverage

## Getting Started

The easiest way to get started is to initialize a flake from a template:

```sh
# Start with a comprehensive suite of tests
nix flake init -t github:ipetkov/crane#quick-start
```

Otherwise check out the [examples and templates] for more detailed examples. An
[API Reference] is also available.

## Compatibility Policy

Breaking changes can land on the `master` branch at any time, so it is
recommended you use a versioning strategy when consuming this library (for
example, using something like flakes or [niv]).

Tagged releases will be cut periodically and changes will be documented in the
[CHANGELOG]. Release versions will follow [Semantic Versioning].

The test suite is run against the latest stable nixpkgs release, as well as
`nixpkgs-unstable`. Any breakage on those channels is considered a bug and
should be reported as such.

## License

This project is licensed under the MIT license.

### Contribution

Unless you explicitly state otherwise, any contribution intentionally submitted
for inclusion by you, shall be licensed as MIT, without any additional terms or
conditions.

[API reference]: https://crane.dev/API.html
[cargo-audit]: https://rustsec.org/
[cargo]: https://doc.rust-lang.org/cargo/
[cargo-nextest]: https://nexte.st/
[cargo-tarpaulin]: https://github.com/xd009642/tarpaulin
[CHANGELOG]: ./CHANGELOG.md
[clippy]: https://github.com/rust-lang/rust-clippy
[custom-toolchain]: ./examples/custom-toolchain/flake.nix
[examples and templates]: https://crane.dev/getting-started.html
[niv]: https://github.com/nmattia/niv
[Nix]: https://nixos.org/
[rustfmt]: https://github.com/rust-lang/rustfmt
[Semantic Versioning]: http://semver.org/spec/v2.0.0.html
