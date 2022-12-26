Build a cargo project with a custom toolchain (e.g. WASM builds):

```sh
nix flake init -t github:ipetkov/crane#custom-toolchain
```

Alternatively, copy and paste the following `flake.nix`:

```nix
{{#include ../../examples/custom-toolchain/flake.nix}}
```
