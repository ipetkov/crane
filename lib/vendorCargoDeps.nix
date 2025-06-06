{
  findCargoFiles,
  lib,
  vendorMultipleCargoDeps,
}:

args:
let
  inherit (builtins)
    pathExists
    readFile
    ;

  inherit (lib.attrsets) optionalAttrs;

  origSrc = src: if src ? _isLibCleanSourceWith then src.origSrc else src;

  cargoConfigs = if args ? src then (findCargoFiles (origSrc args.src)).cargoConfigs else [ ];

  src = origSrc (
    args.src or (throw ''
      unable to find `src` attribute. consider one of the following:
      - set `cargoVendorDir = vendorCargoDeps { cargoLock = ./some/path/to/Cargo.lock; }`
      - set `cargoVendorDir = vendorCargoDeps { src = ./src/containing/cargo/lock/file; }`
      - set `cargoVendorDir = null` to skip vendoring altogether
    '')
  );

  cargoLock = args.cargoLock or (src + "/Cargo.lock");
  cargoLockContents =
    args.cargoLockContents or (
      if pathExists cargoLock then
        readFile cargoLock
      else
        throw ''
          unable to find Cargo.lock at ${src}. please ensure one of the following:
          - a Cargo.lock exists at the root of the source directory of the derivation,
            it is *not* included in .gitignore, and that it is at least staged with git
            via `git add -N Cargo.lock`
          - set `cargoVendorDir = vendorCargoDeps { cargoLock = ./some/path/to/Cargo.lock; }`
          - set `cargoVendorDir = vendorCargoDeps { src = ./src/containing/cargo/lock/file; }`
          - set `cargoVendorDir = null` to skip vendoring altogether
        ''
    );

  lock = args.cargoLockParsed or (builtins.fromTOML cargoLockContents);
in
vendorMultipleCargoDeps (
  {
    inherit cargoConfigs;
    cargoLockParsedList = [ lock ];
    outputHashes = args.outputHashes or { };
    overrideVendorCargoPackage = args.overrideVendorCargoPackage or (_: drv: drv);
    overrideVendorGitCheckout = args.overrideVendorGitCheckout or (_: drv: drv);
  }
  // optionalAttrs (args ? registries) { inherit (args) registries; }
)
