{ lib }:
let
  inherit (lib.fileset)
    fileFilter
    maybeMissing
    unions;
in
# A fileset that includes the minimum files needed to build a Rust project with Cargo
path: unions [
  # Cargo files
  (fileFilter (file: file.name == "Cargo.toml" || file.name == "Cargo.lock") path)
  (maybeMissing (path + ./.cargo/config.toml))
  # any Rust source files
  (fileFilter (file: file.hasExt "rs") path)
]
