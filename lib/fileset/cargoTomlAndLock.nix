{ lib
}:

path:
lib.fileset.fileFilter
  (file: lib.elem file.name [ "Cargo.toml" "Cargo.lock" ])
  path
