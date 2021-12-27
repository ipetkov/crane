{ lib
, myPkgs
, newScope
}:

lib.makeScope newScope (self:
  let
    callPackage = self.newScope { };
  in
  myPkgs // {
    inherit callPackage;

    buildWithCargo = callPackage ./buildWithCargo.nix { };
    downloadCargoPackage = callPackage ./downloadCargoPackage.nix { };
    urlForCargoPackage = callPackage ./urlForCargoPackage.nix { };
    vendorCargoDeps = callPackage ./vendorCargoDeps.nix { };
  })
