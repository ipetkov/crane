To cross compiling a rust program for windows, run the following in a fresh
directory:

```sh
nix flake init -t github:ipetkov/crane#cross-windows
```

Alternatively, if you have an existing project already, copy and paste the
following `flake.nix`:

```nix
{{#include ../../examples/cross-windows/flake.nix}}
```
