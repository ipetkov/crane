{ findCargoFiles
, lib
, vendorMultipleCargoDeps
}:

args:
let
  inherit (builtins)
    pathExists
    readFile;

  inherit (lib.attrsets) optionalAttrs;

  cargoConfigs = if args ? src then (findCargoFiles args.src).cargoConfigs else [ ];

  src = args.src or (throw ''
    unable to find `src` attribute. consider one of the following:
    - set `cargoVendorDir = vendorCargoDeps { cargoLock = ./some/path/to/Cargo.lock; }`
    - set `cargoVendorDir = vendorCargoDeps { src = ./src/containing/cargo/lock/file; }`
    - set `cargoVendorDir = null` to skip vendoring altogether
  '');

  cargoLock = args.cargoLock or (src + "/Cargo.lock");
  cargoLockContents = args.cargoLockContents or (
    if pathExists cargoLock
    then readFile cargoLock
    else
      throw ''
        unable to find Cargo.lock at ${src}. please ensure one of the following:
        - a Cargo.lock exists at the root of the source directory of the derivation
        - set `cargoVendorDir = vendorCargoDeps { cargoLock = ./some/path/to/Cargo.lock; }`
        - set `cargoVendorDir = vendorCargoDeps { src = ./src/containing/cargo/lock/file; }`
        - set `cargoVendorDir = null` to skip vendoring altogether
      ''
  );

  lock = args.cargoLockParsed or (builtins.fromTOML cargoLockContents);
in
vendorMultipleCargoDeps ({
  inherit cargoConfigs;
  cargoLockParsedList = [ lock ];
} // optionalAttrs (args ? registries) { inherit (args) registries; })
