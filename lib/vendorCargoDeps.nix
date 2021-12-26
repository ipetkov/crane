{ downloadCargoPackage
, linkFarm
}:

{ cargoLock ? throw "either cargoLock or cargoLockContents must be specified"
, cargoLockContents ? builtins.readFile cargoLock
}:
let
  lock = builtins.fromTOML cargoLockContents;

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
