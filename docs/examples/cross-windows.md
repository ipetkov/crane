To cross-compile a Rust application for Windows, run the following in a fresh directory:

```sh
nix flake init -t github:ipetkov/crane#cross-windows
```

Alternatively, if you have an existing project already, copy and paste the
following `flake.nix`:

```nix
{{#include ../../examples/cross-windows/flake.nix}}
```


The `cross-windows-rust-overlay` template/example is a version of the above using `oxalica/rust-overlay` and the `cross-windows-sqlite` template/example is a version of the above containing a Rust application that uses SQLx and SQLite.
