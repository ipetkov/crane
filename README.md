# Crane

A [Nix](https://nixos.org/) library for building [cargo](https://doc.rust-lang.org/cargo/) projects.

* **No messing with hashes**: a Cargo.lock file is all you need
* **Incremental**: never build a dependency twice with easy artifact caching
* **Composable**: split builds and tests into granular steps. Gate CI without
  burdening downstream consumers building from source.

Detailed [API docs] are available.

## Getting Started

The easiest way to get started is to initialize a flake from a template:

```sh
# Start with a comprehensive suite of tests
nix flake init -t github:ipetkov/crane#quick-start

# Or if you want something simpler
nix flake init -t github:ipetkov/crane#quick-start-simple

# If you need a custom rust toolchain (e.g. to build WASM targets):
nix flake init -t github:ipetkov/crane#custom-toolchain
```

For an even more lean, no frills set up, create a `flake.nix` file with the
following contents at the root of your cargo workspace:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    crane.url = "github:ipetkov/crane";
    crane.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, crane, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system: {
      defaultPackage = crane.lib.${system}.buildPackage {
        src = ./.;
      };
    });
}
```

## FAQs

### I want to use a custom version of nixpkgs or another specific system

The crane library can be instantiated with a specific version of nixpkgs as
follows. For more information, see the [API docs] for `mkLib`.

```nix
crane.mkLib (import nixpkgs { system = "armv7l-linux"; })
```

### I want to override a particular package used by the crane library

Specific inputs can be overridden for the entire library via the
`overrideScope'` API as follows. For more information, see the [API docs] for
`mkLib` or checkout the [custom-toolchain] example.

```nix
crane.lib.${system}.overrideScope' (final: prev: {
  cargo = myCustomCargoVersion;
})
```

### My custom rust flags are getting ignored

If you are using a `build.rustflags` definition in `.cargo/config.toml`,
consider turning off source prefix remapping by adding
`doRemapSourcePathPrefix = false;` in your derivation.

See the [API docs] for `remapSourcePathPrefixHook` for more information.

### Nix is complaining about IFD (import from derivation)

If a derivation's `pname` and `version` attributes are not explicitly set,
crane will inspect the project's `Cargo.toml` file to set them as a convenience
to avoid duplicating that information by hand. This works well when the source
is a local path, but can cause issues if the source is being fetched remotely,
or flakes are not being used (since flakes have IFD enabled on by default).

One easy workaround for this issue (besides enabling the
`allow-import-from-derivation` option in Nix) is to explicitly set
`{ pname = "..."; version = "..."; }` in the derivation.

You'll know you've run into this issue if you see error messages along the lines
of:
* `cannot build '/nix/store/...-source.drv' during evaluation because the option 'allow-import-from-derivation' is disabled`
* `a 'aarch64-darwin' with features {} is required to build '/nix/store/...', but I am a 'x86_64-linux' with features {}`

## License

This project is licensed under the [MIT license].

### Contribution

Unless you explicitly state otherwise, any contribution intentionally submitted
for inclusion by you, shall be licensed as MIT, without any additional terms or
conditions.

[API docs]: ./docs/API.md
[custom-toolchain]: ./examples/custom-toolchain/flake.nix
[MIT license]: ./LICENSE
