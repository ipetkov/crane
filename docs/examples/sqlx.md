To build a cargo project which depends on the SQLx crate, run the following in a
fresh directory:

```sh
nix flake init -t github:ipetkov/crane#sqlx
```

Alternatively, if you have an existing project already, copy and paste the
following `flake.nix`:

```nix
{{#include ../../examples/sqlx/flake.nix}}
```
