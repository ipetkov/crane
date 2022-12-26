# Summary

[Home](../README.md)
[Changelog](../CHANGELOG.md)

---
* [Introduction](./introduction.md)
  * [Artifact reuse](./introduction/artifact-reuse.md)
  * [Sequential builds](./introduction/sequential-builds.md)
* [Getting started](./getting-started.md)
  * [Quick start](./examples/quick-start.md)
  * [Quick start (simple)](./examples/quick-start-simple.md)
  * [Custom toolchain](./examples/custom-toolchain.md)
  * [Alternative registry](./examples/alt-registry.md)
  * [Cross compiling](./examples/cross-rust-overlay.md)
  * [Cross compiling with musl](./examples/cross-musl.md)
---
- [API Reference](./API.md)
---
* [Troubleshooting/FAQ](./faq/faq.md)
  * [Customizing nixpkgs and other inputs](./faq/custom-nixpkgs.md)
  * [IFD (import from derivation) errors](./faq/ifd-error.md)
  * [Constantly rebuilding from scratch](./faq/constant-rebuilds.md)
  * [Building upstream cargo crate with no `Cargo.lock`](./faq/no-cargo-lock.md)
  * [Patching `Cargo.lock` during build](./faq/patching-cargo-lock.md)
  * [Building a subset of a workspace](./faq/build-workspace-subset.md)
