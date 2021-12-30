{ fromTOML
, lib
, myPkgs
, newScope
, toTOML
}:

lib.makeScope newScope (self:
  let
    callPackage = self.newScope { };
  in
  myPkgs // {
    inherit callPackage fromTOML toTOML;

    buildWithCargo = callPackage ./buildWithCargo.nix { };
    cleanCargoToml = callPackage ./cleanCargoToml.nix { };
    downloadCargoPackage = callPackage ./downloadCargoPackage.nix { };
    urlForCargoPackage = callPackage ./urlForCargoPackage.nix { };
    vendorCargoDeps = callPackage ./vendorCargoDeps.nix { };
  })
