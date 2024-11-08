{ fileset
, lib
}:

path:
lib.fileset.unions [
  (fileset.cargoTomlAndLock path)
  (fileset.rust path)
  # Keep all toml files as they are commonly used to configure other
  # cargo-based tools
  (fileset.toml path)
]
