To build a cargo project with musl to crate statically linked binaries, run the
following in a fresh directory:

```sh
nix flake init -t github:ipetkov/crane#cross-musl
```

Alternatively, if you have an existing project already, copy and paste the
following `flake.nix`:

```nix
{{#include ../../examples/cross-musl/flake.nix}}
```
