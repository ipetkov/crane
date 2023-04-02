# Examples

This directory contains several different ways of configuring a project:

* **alt-registry**: build a cargo project which uses another crate registry
  besides crates.io
* **build-std**: build a cargo project which requires building the
  standard library and other crates distributed with the Rust toolchain
* **cross-musl**: build a cargo project with musl to crate statically linked
  binaries
* **cross-rust-overlay**: cross compile a rust project using rust-overlay
* **cross-windows**: cross compile a rust project for windows
* **custom-toolchain**: build a cargo project with a custom toolchain (e.g. WASM
  builds)
* **quick-start**: build a cargo project with a comprehensive test suite
* **quick-start-simple**: build a cargo project without extra tests
