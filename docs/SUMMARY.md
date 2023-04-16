# Summary

[Home](./README.md)
[Changelog](./CHANGELOG.md)

---
* [Introduction](./introduction.md)
  * [Artifact reuse](./introduction/artifact-reuse.md)
  * [Sequential builds](./introduction/sequential-builds.md)
* [Getting started](./getting-started.md)
  * [Quick start](./examples/quick-start.md)
  * [Quick start (simple)](./examples/quick-start-simple.md)
  * [Custom toolchain](./examples/custom-toolchain.md)
  * [Alternative registry](./examples/alt-registry.md)
  * [Building standard library crates](./examples/build-std.md)
  * [Cross compiling](./examples/cross-rust-overlay.md)
  * [Cross compiling with musl](./examples/cross-musl.md)
  * [Cross compiling to windows](./examples/cross-windows.md)
* [Source filtering](./source-filtering.md)
* [Local development](./local_development.md)
* [Custom cargo commands](./custom_cargo_commands.md)
* [Customizing builds](./customizing_builds.md)
---
- [API Reference](./API.md)
---
* [Troubleshooting/FAQ](./faq/faq.md)
  * [Customizing nixpkgs and other inputs](./faq/custom-nixpkgs.md)
  * [IFD (import from derivation) errors](./faq/ifd-error.md)
  * [Constantly rebuilding from scratch](./faq/constant-rebuilds.md)
  * [Crates being rebuilt when using different toolchains](./faq/rebuilds-with-different-toolchains.md)
  * [Building upstream cargo crate with no `Cargo.lock`](./faq/no-cargo-lock.md)
  * [Patching `Cargo.lock` during build](./faq/patching-cargo-lock.md)
  * [Building a subset of a workspace](./faq/build-workspace-subset.md)
  * [Trouble building when using `include_str!` (or including other non-rust files)](./faq/building-with-non-rust-includes.md)
  * [Dealing with sandbox-unfriendly build scripts](./faq/sandbox-unfriendly-build-scripts.md)
  * [Cargo.toml is not at the source root](./faq/workspace-not-at-source-root.md)
---
* [Advanced Techniques](./advanced/advanced.md)
  * [Overriding function behavior](./advanced/overriding-function-behavior.md)
