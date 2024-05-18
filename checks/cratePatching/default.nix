{ buildPackage
, cleanCargoSource
, lib
, vendorCargoDeps
, runCommand
}:

let
  src = cleanCargoSource ../simple-git-workspace-inheritance;

  isCraneTestRepo = lib.any (p: lib.hasPrefix "git+https://github.com/ipetkov/crane-test-repo.git#" p.source);
  bin = buildPackage {
    inherit src;
    cargoVendorDir = vendorCargoDeps {
      inherit src;
      overrideVendorGitCheckout = ps: drv:
        if isCraneTestRepo ps then
          drv.overrideAttrs
            (_old: {
              patches = [
                ./0001-patch-test-repo.patch
              ];
            })
        else
          drv;

      overrideVendorCargoPackage = p: drv:
        if p.name == "byteorder" then
          drv.overrideAttrs
            (_old: {
              patches = [
                ./0002-patch-byteorder.patch
              ];
            })
        else
          drv;
    };
  };
in
runCommand "runPatchedBin" { } ''
  diff <(echo -e 'greetings, crane!\n') <(${bin}/bin/simple-git-workspace-inheritance)
  touch $out
''
