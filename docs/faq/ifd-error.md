## Nix is complaining about IFD (import from derivation)

If a derivation's `pname` and `version` attributes are not explicitly set,
crane will inspect the project's `Cargo.toml` file to set them as a convenience
to avoid duplicating that information by hand. This works well when the source
is a local path, but can cause issues if the source is being fetched remotely,
or flakes are not being used (since flakes have IFD enabled on by default).

One easy workaround for this issue (besides enabling the
`allow-import-from-derivation` option in Nix) is to explicitly set
`{ pname = "..."; version = "..."; }` in the derivation.

You'll know you've run into this issue if you see error messages along the lines
of:
* `cannot build '/nix/store/...-source.drv' during evaluation because the option 'allow-import-from-derivation' is disabled`
* `a 'aarch64-darwin' with features {} is required to build '/nix/store/...', but I am a 'x86_64-linux' with features {}`
