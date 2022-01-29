{ fromTOML
, lib
, myPkgs
, newScope
, toTOML
}:

lib.makeScope newScope (self:
  let
    callPackage = self.newScope myPkgs;
  in
  {
    inherit fromTOML toTOML;

    buildDepsOnly = callPackage ./buildDepsOnly.nix { };
    buildPackage = callPackage ./buildPackage.nix { };
    cargoBuild = callPackage ./cargoBuild.nix { };
    cargoClippy = callPackage ./cargoClippy.nix { };
    cargoFmt = callPackage ./cargoFmt.nix { };
    cargoTarpaulin = callPackage ./cargoTarpaulin.nix { };
    cleanCargoToml = callPackage ./cleanCargoToml.nix { };
    crateNameFromCargoToml = callPackage ./crateNameFromCargoToml.nix { };
    downloadCargoPackage = callPackage ./downloadCargoPackage.nix { };
    findCargoFiles = callPackage ./findCargoFiles.nix { };
    mkCargoDerivation = callPackage ./mkCargoDerivation.nix { };
    mkDummySrc = callPackage ./mkDummySrc.nix { };
    urlForCargoPackage = callPackage ./urlForCargoPackage.nix { };
    vendorCargoDeps = callPackage ./vendorCargoDeps.nix { };
    writeTOML = callPackage ./writeTOML.nix { };
  })
