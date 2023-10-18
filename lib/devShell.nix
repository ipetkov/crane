{ cargo
, clippy
, mkShell
, rustc
, rustfmt
}:

{ checks ? { }
, inputsFrom ? [ ]
, packages ? [ ]
, ...
}@args:
let
  inherit (builtins) removeAttrs;

  cleanedArgs = removeAttrs args [
    "checks"
    "inputsFrom"
    "nativeBuildInputs"
  ];
in
mkShell (cleanedArgs // {
  inputsFrom = builtins.attrValues checks ++ inputsFrom;

  packages = [
    rustc
    cargo
    clippy
    rustfmt
  ] ++ packages;
})
