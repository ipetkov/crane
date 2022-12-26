Build a cargo project without extra tests:

```sh
nix flake init -t github:ipetkov/crane#quick-start-simple
```

Alternatively, copy and paste the following `flake.nix`:

```nix
{{#include ../../examples/quick-start-simple/flake.nix}}
```
