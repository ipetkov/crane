{ lib
, linkFarmFromDrvs
, mkDummySrc
, runCommand
}:

let
  cmpDummySrcRaw = name: input: expected:
    let
      dummySrc = mkDummySrc {
        src = input;
      };
    in
    runCommand "compare-${name}" { } ''
      echo ${expected} ${dummySrc}
      diff -r ${expected} ${dummySrc}
      touch $out
    '';

  cmpDummySrc = name: path:
    let
      expected = path + "/expected";
      input = path + "/input";

      # Regression test for https://github.com/ipetkov/crane/issues/46
      filteredInput = lib.cleanSourceWith {
        src = input;
        filter = path: type:
          let baseName = builtins.baseNameOf path;
          in
          type == "directory" || lib.any (s: lib.hasPrefix s (builtins.baseNameOf path)) [
            "Cargo"
            "config"
          ];
      };
    in
    [
      (cmpDummySrcRaw name input expected)
      (cmpDummySrcRaw "${name}-filtered" filteredInput expected)
    ];
in
linkFarmFromDrvs "cleanCargoToml" (lib.flatten [
  (cmpDummySrc "single" ./single)
  (cmpDummySrc "single-alt" ./single-alt)
  (cmpDummySrc "workspace" ./workspace)
])
