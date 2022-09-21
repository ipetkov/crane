{ lib
}:

orig_path: type:
let
  path = (toString orig_path);
  base = baseNameOf path;
  parentDir = baseNameOf (dirOf path);

  matchesSuffix = lib.any (suffix: lib.hasSuffix suffix base) [
    # Keep rust sources
    ".rs"
    # Keep all toml files as they are commonly used to configure other
    # cargo-based tools
    ".toml"
  ];

  # Cargo.toml already captured above
  isCargoFile = base == "Cargo.lock";

  # .cargo/config.toml already captured above
  isCargoConfig = parentDir == ".cargo" && base == "config";
in
type == "directory" || matchesSuffix || isCargoFile || isCargoConfig
