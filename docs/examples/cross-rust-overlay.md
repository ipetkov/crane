Cross compile a rust project using `oxalica/rust-overlay`:

```sh
nix flake init -t github:ipetkov/crane#cross-rust-overlay
```

Alternatively, copy and paste the following `flake.nix`:

```nix
{{#include ../../examples/cross-rust-overlay/flake.nix}}
```
