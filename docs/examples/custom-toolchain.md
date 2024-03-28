To build a cargo project with a custom toolchain (e.g. WASM builds), run the
following in a fresh directory:

```sh
nix flake init -t github:ipetkov/crane#custom-toolchain
```

Alternatively, if you have an existing project already, copy and paste the
following `flake.nix`:

```nix
{{#include ../../examples/custom-toolchain/flake.nix}}
```
