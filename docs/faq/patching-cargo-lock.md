## I need to patch `Cargo.lock` but when I do the build fails

Dependency crates are vendored by reading `Cargo.lock` _at evaluation time_ and
not at build time. Thus using `patches = [ ./patch-which-updates-lockfile.patch ];`
may result in a situation where any new crates introduced by the patch cannot be
found by cargo.

It is possible to work around this limitation by patching `Cargo.lock` in a
stand-alone derivation and passing that result to `vendorCargoDeps` before
building the rest of the workspace.

```nix
let
  patchedCargoLock = src = pkgs.stdenv.mkDerivation {
    src = ./path/to/Cargo.lock;
    patches = [
      ./update-cargo-lock.patch
    ];
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp Cargo.lock $out
      runHook postInstall
    '';
  };
in
craneLib.buildPackage {
  cargoVendorDir = craneLib.vendorCargoDeps {
    src = patchedCargoLock;
  };

  src = craneLib.cleanCargoSource ./.;

  patches = [
    ./update-cargo-lock.patch
    ./some-other.patch
  ];
}
```
