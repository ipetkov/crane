To build a cargo project without extra tests, run the following in a fresh
directory:

```sh
nix flake init -t github:ipetkov/crane#quick-start-simple
```

Alternatively, if you have an existing project already, copy and paste the
following `flake.nix`:

```nix
{{#include ../../examples/quick-start-simple/flake.nix}}
```
