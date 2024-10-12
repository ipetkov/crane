To build a cargo project which uses another crate registry, run the following in
a fresh directory:

```sh
nix flake init -t github:ipetkov/crane#alt-registry
```

Alternatively, if you have an existing project already:

1. Ensure that declaration of the registry and its index url are present in
   `.cargo/config.toml`
1. Either commit `.cargo/config.toml` or ensure it is staged in git (`git add -N .cargo/config.toml`)
1. Copy and paste the following `flake.nix`:

```nix
{{#include ../../examples/alt-registry/flake.nix}}
```
