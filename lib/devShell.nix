{ lib
, mkShell
, rustPlatform
, cargo
, rustc
, pkgs
}:

{ checks ? { }
, inputsFrom ? [ ]
, packages ? [ ]
, rust-analyzer ? pkgs.rust-analyzer
, ...
}@args:
let
  inherit (builtins) removeAttrs;

  cleanedArgs = removeAttrs args [
    "checks"
    "inputsFrom"
    "nativeBuildInputs"
    "rust-analyzer"
  ];
in
mkShell (cleanedArgs // {
  inputsFrom = builtins.attrValues checks ++ inputsFrom;

  packages =
    [
      rustc
      cargo
    ]
    ++ lib.optional (rust-analyzer != null) rust-analyzer
    ++ packages;
}
  // lib.optionalAttrs (rust-analyzer != null) {
  RUST_SRC_PATH = rustPlatform.rustLibSrc;
})
