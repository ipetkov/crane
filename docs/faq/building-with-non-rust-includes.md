## I'm having trouble building a project which uses `include_str!`

Double check if the source passed into the derivation is being cleaned or
filtered in anyway. Using `craneLib.cleanCargoSource` (or
`craneLib.filterCargoSources` directly) will omit any non-cargo and non-rust
files before trying to build the derivation. Thus if the project is trying to
use `include_str!`, `include_bytes!`, or any other attempt at accessing such a
file you may need to tweak the source filter to ensure the files are included.

Check out the [source filtering](../source-filtering.md) section for more info!
