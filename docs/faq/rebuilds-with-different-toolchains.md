## Dependencies being rebuilt even with proper source filtering applied

If the dependency crates are being rebuilt even after proper source filtering
has been applied (i.e. the `crate-depsOnly` derivation is NOT being rebuilt)
check that the same Rust/Cargo toolchain is being used when building artifacts
and vendoring crate sources.

The crate artifacts can only be used for the same compiler version, so if cargo
sees artifacts for the wrong toolchain it will rebuild everything from scratch.

Note that each instance of `crane` tied to a single Rust toolchain (by default
the one available in `nixpkgs`, but this can be overridden by the caller). If
you are using multiple `craneLib` instantiations and you see this occurring,
double check that they aren't being created with a different toolchain
(especially if cross-compilation is being used for the project).
