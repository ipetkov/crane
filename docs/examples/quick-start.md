To build a cargo project with a comprehensive test suite, run the following in a
fresh directory:

```sh
nix flake init -t github:ipetkov/crane#quick-start
```

Alternatively, if you have an existing project already, copy and paste the
following `flake.nix`:

```nix
{{#include ../../examples/quick-start/flake.nix}}
```
