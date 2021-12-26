{ lib
, newScope
}:

lib.makeScope newScope (self:
  let
    callPackage = self.newScope { };
  in
  {
    inherit callPackage;

    downloadCargoPackage = callPackage ./downloadCargoPackage.nix { };
    urlForCargoPackage = callPackage ./urlForCargoPackage.nix { };
    vendorCargoDeps = callPackage ./vendorCargoDeps.nix { };
  })
