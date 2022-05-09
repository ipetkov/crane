{ linkFarmFromDrvs
, mkDummySrc
, runCommand
}:

let
  cmpDummySrc = name: path:
    let
      dummySrc = mkDummySrc {
        src = path + "/input";
      };
    in
    runCommand "compare-${name}" { } ''
      diff -r ${path + /expected} ${dummySrc}
      touch $out
    '';
in
linkFarmFromDrvs "cleanCargoToml" [
  (cmpDummySrc "single" ./single)
  (cmpDummySrc "single-alt" ./single-alt)
  (cmpDummySrc "workspace" ./workspace)
]
