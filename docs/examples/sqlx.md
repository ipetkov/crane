Build a cargo project which depends on the SQLx crate:

```sh
nix flake init -t github:ipetkov/crane#sqlx
```

Alternatively, copy and paste the following `flake.nix`:

```nix
{{#include ../../examples/sqlx/flake.nix}}
```
