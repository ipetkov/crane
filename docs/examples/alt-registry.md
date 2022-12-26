Build a cargo project which uses another crate registry:

```sh
nix flake init -t github:ipetkov/crane#alt-registry
```

Alternatively, copy and paste the following `flake.nix`:

```nix
{{#include ../../examples/alt-registry/flake.nix}}
```
