{ runCommandLocal
}:

bins: drv:
let
  testList = map (b: "${drv}/bin/${b}") bins;
  tests = builtins.concatStringsSep "\n" testList;
in
runCommandLocal "smoke-${drv.name}" { } ''
  # does it run?
  ${tests}
  touch $out
''
