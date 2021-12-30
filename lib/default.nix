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

    buildWithCargo = callPackage ./buildWithCargo.nix { };
    buildWithDummySrc = callPackage ./buildWithDummySrc.nix { };
    cleanCargoToml = callPackage ./cleanCargoToml.nix { };
    crateNameFromCargoToml = callPackage ./crateNameFromCargoToml.nix { };
    downloadCargoPackage = callPackage ./downloadCargoPackage.nix { };
    mkDummySrc = callPackage ./mkDummySrc.nix { };
    urlForCargoPackage = callPackage ./urlForCargoPackage.nix { };
    vendorCargoDeps = callPackage ./vendorCargoDeps.nix { };
    writeTOML = callPackage ./writeTOML.nix { };
  })
