To cross compile a rust project using `oxalica/rust-overlay`, run the following
in a fresh directory:

```sh
nix flake init -t github:ipetkov/crane#cross-rust-overlay
```

Alternatively, if you have an existing project already, copy and paste the
following `flake.nix`:

```nix
{{#include ../../examples/cross-rust-overlay/flake.nix}}
```
