Build a cargo project while also compiling the standard library or other crates
distributed with the Rust toolchain:

```sh
nix flake init -t github:ipetkov/crane#build-std
```

Alternatively, copy and paste the following `flake.nix`:

```nix
{{#include ../../examples/build-std/flake.nix}}
```
