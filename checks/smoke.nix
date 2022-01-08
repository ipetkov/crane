{ runCommand
}:

bins: drv:
let
  testList = map (b: "${drv}/bin/${b}") bins;
  tests = builtins.concatStringsSep "\n" testList;
in
runCommand "smoke-${drv.name}" { } ''
  # does it run?
  ${tests}
  touch $out
''
