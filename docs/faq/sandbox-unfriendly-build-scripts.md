## Dealing with sandbox-unfriendly build scripts

In general, most build scripts used by popular Rust projects are pretty good at
only attempting to write to cargo's output directory. But every once in a while
it is possible to find a build script somewhere deep in the dependency tree
which assumes it can happily write to any directory it wants to (i.e. wherever
its own sources happen to be present). For build scripts like these the best
long term approach is almost always to fix them upstream; [cargo's own
documentation also warns against
this](https://doc.rust-lang.org/cargo/reference/build-script-examples.html#code-generation):

> In general, build scripts should not modify any files outside of OUT_DIR. It
> may seem fine on the first blush, but it does cause problems when you use such
> crate as a dependency, because there's an implicit invariant that sources in
> .cargo/registry should be immutable. cargo won't allow such scripts when
> packaging.

As a dire last resort it is possible to copy all vendored sources out of the
(read-only) Nix store and into a writable directory. Keep in mind that doing so
requires recursively copying _all sources of all crates_ the project depends on
_during every single build_; it comes with a performance _and_ energy cost, and
as such **it is not recommended**.

```nix
# You have been warned
buildPackage {
  # other attributes omtited
  postPatch = ''
    mkdir -p "$TMPDIR/nix-vendor"
    cp -r "$cargoVendorDir" -T "$TMPDIR/nix-vendor"
    chmod -R +w "$TMPDIR/nix-vendor"
    cargoVendorDir="$TMPDIR/nix-vendor"
  '';
}
```
