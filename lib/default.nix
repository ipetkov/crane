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
    buildWithCargo = callPackage ./buildWithCargo.nix { };
    cleanCargoToml = callPackage ./cleanCargoToml.nix { };
    crateNameFromCargoToml = callPackage ./crateNameFromCargoToml.nix { };
    downloadCargoPackage = callPackage ./downloadCargoPackage.nix { };
    mkCargoDerivation = callPackage ./mkCargoDerivation.nix { };
    mkDummySrc = callPackage ./mkDummySrc.nix { };
    urlForCargoPackage = callPackage ./urlForCargoPackage.nix { };
    vendorCargoDeps = callPackage ./vendorCargoDeps.nix { };
    vendorCargoDepsFromArgs = callPackage ./vendorCargoDepsFromArgs.nix { };
    writeTOML = callPackage ./writeTOML.nix { };
  })
