## Getting Started

The easiest way to get started is to initialize a flake from a template:

```sh
# Start with a comprehensive suite of tests
nix flake init -t github:ipetkov/crane#quick-start

# Or if you want something simpler
nix flake init -t github:ipetkov/crane#quick-start-simple

# If you need a custom rust toolchain (e.g. to build WASM targets):
nix flake init -t github:ipetkov/crane#custom-toolchain

# If you need to use another crate registry besides crates.io
nix flake init -t github:ipetkov/crane#alt-registry

# If you need cross-compilation, you can also try out
nix flake init -t github:ipetkov/crane#cross-rust-overlay

# For statically linked binaries using musl
nix flake init -t github:ipetkov/crane#cross-musl

# If you are building a WASM webapp with trunk
nix flake init -t github:ipetkov/crane#trunk

# If you are building a workspace with trunk member
nix flake init -t github:ipetkov/crane#trunk-workspace

# If you would like to perform end to end testing of a webapp
nix flake init -t github:ipetkov/crane#end-to-end-testing
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
  };

  outputs = { self, nixpkgs, crane, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        craneLib = crane.mkLib pkgs;
      in
    {
      packages.default = craneLib.buildPackage {
        src = craneLib.cleanCargoSource (craneLib.path ./.);

        # Add extra inputs here or any other derivation settings
        # doCheck = true;
        # buildInputs = [];
        # nativeBuildInputs = [];
      };
    });
}
```
