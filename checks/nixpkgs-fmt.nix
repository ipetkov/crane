{ lib
, nixpkgs-fmt
, runCommand
}:

let
  cleaned = lib.cleanSource ./..;
  nixOnly = lib.sourceFilesBySuffices cleaned [ ".nix" ];
in
runCommand "nixpkgs-fmt"
{
  nativeBuildInputs = [ nixpkgs-fmt ];
} ''
  nixpkgs-fmt --check ${nixOnly}
  touch $out # it worked!
''
