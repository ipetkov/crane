The crane library can be instantiated with a specific version of nixpkgs as
follows. For more information, see the [API docs] for `mkLib`.

```nix
# Instantiating for a specific `system`
crane.mkLib (import nixpkgs {
  system = "armv7l-linux";
})
```

```nix
# Instantiating for cross compiling
crane.mkLib (import nixpkgs {
  localSystem = "x86_64-linux";
  crossSystem = "aarch64-linux";
})
```

The crane library can also be instantiated with a particular rust toolchain:

```nix
# For example, using rust-overlay
let
  system = "x86_64-linux";
  pkgs = import nixpkgs {
    inherit system;
    overlays = [ (import rust-overlay) ];
  };

  rustToolchain = pkgs.rust-bin.stable.latest.default.override {
    targets = [ "wasm32-wasi" ];
  };
in
(crane.mkLib pkgs).overrideToolchain rustToolchain
```

Finally, specific inputs can be overridden for the entire library via the
`overrideScope'` API as follows. For more information, see the [API
docs](../API.md) for `mkLib`/`overrideToolchain`, or checkout the
[custom-toolchain](../../examples/custom-toolchain) example.

```nix
crane.lib.${system}.overrideScope' (final: prev: {
  cargo-tarpaulin = myCustomCargoTarpaulinVersion;
})
```

[API docs]: ../API.md
