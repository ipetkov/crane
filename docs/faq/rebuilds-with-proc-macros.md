## Constantly rebuilding proc-macro dependencies `dev` mode

A regression was introduced sometime around Rust 1.71.1 which [changed how
debuginfo flags are passed to proc-macro crates when using a `dev`
profile](https://github.com/rust-lang/cargo/issues/12457).

If you are building with a `dev` profile (i.e. _not_ using `release` builds),
you may want to set the following in `.cargo/config.toml`:

```toml
[profile.dev.build-override]
debug = false
```
