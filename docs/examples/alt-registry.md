To build a cargo project which uses another crate registry, run the following in
a fresh directory:

```sh
nix flake init -t github:ipetkov/crane#alt-registry
```

Alternatively, if you have an existing project already, copy and paste the
following `flake.nix`:

```nix
{{#include ../../examples/alt-registry/flake.nix}}
```
