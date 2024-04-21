> Note that it is *highly* recommended to use something like `cargo-hakari`
> to avoid cache misses when building various workspace crates.

To build a cargo workspace with a comprehensive test suite, run the following in
a fresh directory:

```sh
nix flake init -t github:ipetkov/crane#quick-start-workspace
```

Alternatively, if you have an existing project already, copy and paste the
following `flake.nix`:

```nix
{{#include ../../examples/quick-start-workspace/flake.nix}}
```
