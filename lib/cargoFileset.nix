{ lib }:
let
  inherit (lib.fileset)
    fileFilter
    unions;
in
# A fileset that includes the minimum files needed to build a Rust project with Cargo
path: unions [
  # Cargo files (Cargo.toml handled below)
  (fileFilter (file: file.name == "Cargo.lock") path)
  # Keep all toml files as they are commonly used to configure other
  # cargo-based tools
  (fileFilter (file: lib.any file.hasExt [ "rs" "toml" ]) path)
]
