{ lib
}:

path:
lib.fileset.fileFilter
  (file: file.hasExt "toml")
  path
