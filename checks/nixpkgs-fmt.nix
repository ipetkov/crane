{ lib
, nixpkgs-fmt
, runCommandLocal
}:

let
  cleaned = lib.cleanSource ./..;
  nixOnly = lib.sourceFilesBySuffices cleaned [ ".nix" ];
in
runCommandLocal "nixpkgs-fmt"
{
  nativeBuildInputs = [ nixpkgs-fmt ];
} ''
  nixpkgs-fmt --check ${nixOnly}
  touch $out # it worked!
''
