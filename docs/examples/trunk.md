[Trunk](https://trunkrs.dev) is a tool that allow you to build web apps using Rust and webassembly, including compiling scss, and distributing other assets.

Being a more specialized tool, it comes with some constraints that must be noted when using it in combination with crane:

* Your Toolchain must have the `wasm32-unknown-unknown` target installed (See: [Custom toolchain](../custom-toolchain.md))
* For `craneLib.buildDepsOnly` to work you will need to set the build target (See: [API Reference](../API.md#libbuilddepsonly))
* `craneLib.filterCargoSources` will remove html, css, your assets folder, so you need to modify the source filtering function (See: [Source filtering](../source-filtering.md))
* You will need to set `wasm-bindgen-cli` to a version that matches your Cargo.lock file. (See examples)

Quick-start a Trunk project with

```sh
nix flake init -t github:ipetkov/crane#trunk
```

Alternatively, copy and paste the following `flake.nix`:

```nix
{{#include ../../examples/trunk/flake.nix}}
```
