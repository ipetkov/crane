{ lib
}:

path:
lib.fileset.fileFilter
  # Technically this should be scoped to `.cargo/config.toml` but (currently)
  # there is no way to do this with file sets in a generic manner
  (file: file.name == "config.toml")
  path
