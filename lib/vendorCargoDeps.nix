{ downloadCargoPackage
, fromTOML
, linkFarm
}:

args:
let
  src = args.src or (throw ''
    unable to find `src` attribute. consider one of the following:
    - set `cargoVendorDir = vendorCargoDeps { cargoLock = ./some/path/to/Cargo.lock; }`
    - set `cargoVendorDir = vendorCargoDeps { src = ./src/containing/cargo/lock/file; }`
    - set `cargoVendorDir = null` to skip vendoring altogether
  '');

  cargoLock = args.cargoLock or (src + /Cargo.lock);
  cargoLockContents = args.cargoLockContents or (
    if builtins.pathExists cargoLock
    then builtins.readFile cargoLock
    else
      throw ''
        unable to find Cargo.lock at ${src}. please ensure one of the following:
        - a Cargo.lock exists at the root of the source directory of the derivation
        - set `cargoVendorDir = vendorCargoDeps { cargoLock = ./some/path/to/Cargo.lock; }`
        - set `cargoVendorDir = vendorCargoDeps { src = ./src/containing/cargo/lock/file; }`
        - set `cargoVendorDir = null` to skip vendoring altogether
      ''
  );

  lock = fromTOML cargoLockContents;

  packages =
    if lock ? package
    then lock.package
    else throw "Cargo.lock missing [[package]] definitions";

  # The local crate itself will show up in the lock file
  # with no checksum/source, so we don't need to vendor it
  filteredPackages = builtins.filter
    (p: p ? checksum && p ? source)
    lock.package;

  vendoredDeps = map
    (p: {
      name = "${p.name}-${p.version}";
      path = downloadCargoPackage p;
    })
    filteredPackages;

in
linkFarm "cargo-vendored-deps" vendoredDeps
