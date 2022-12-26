Build a cargo project with musl to crate statically linked binaries:

```sh
nix flake init -t github:ipetkov/crane#cross-musl
```

Alternatively, copy and paste the following `flake.nix`:

```nix
{{#include ../../examples/cross-musl/flake.nix}}
```
