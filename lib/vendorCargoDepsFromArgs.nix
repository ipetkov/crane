{ vendorCargoDeps
}:

args:
let
  path = args.src or (throw ''
    unable to find `src` attribute. consider one of the following:
    - set `cargoVendorDir = vendorCargoDepsFromArgs { src = ./src/containing/Cargo.lock; }`
    - set `cargoVendorDir = null` to skip vendoring altogether
  '');
  cargoLock = path + /Cargo.lock;
in
if builtins.pathExists cargoLock
then vendorCargoDeps { inherit cargoLock; }
else
  throw ''
    unable to find Cargo.lock at ${path}. please ensure one of the following:
    - a Cargo.lock exists at the root of the source directory of the derivation
    - set `cargoVendorDir = vendorCargoDeps { cargoLock = ./some/path/to/Cargo.lock; }`
    - set `cargoVendorDir = null` to skip vendoring altogether
  ''
