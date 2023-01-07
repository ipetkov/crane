Cross compiling a rust program for windows:

```sh
nix flake init -t github:ipetkov/crane#cross-windows
```

Alternatively, copy and paste the following `flake.nix`:

```nix
{{#include ../../examples/cross-windows/flake.nix}}
```
