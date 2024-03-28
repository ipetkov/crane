To build a cargo project while also compiling the standard library or other
crates distributed with the Rust toolchain, run the following in a fresh
directory:

```sh
nix flake init -t github:ipetkov/crane#build-std
```

Alternatively, if you have an existing project already, copy and paste the
following `flake.nix`:

```nix
{{#include ../../examples/build-std/flake.nix}}
```
