{ lib
, linkFarmFromDrvs
, mkDummySrc
, runCommand
}:

let
  doCompare = name: expected: actual:
    runCommand "compare-${name}" { } ''
      echo ${expected} ${actual}
      diff -r ${expected} ${actual}
      touch $out
    '';


  cmpDummySrcRaw = name: expected: input:
    let
      dummySrc = mkDummySrc {
        src = input;
      };
    in
    doCompare name expected dummySrc;

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
      (cmpDummySrcRaw name expected input)
      (cmpDummySrcRaw "${name}-filtered" expected filteredInput)
    ];

  customizedDummy =
    let
      expected = ./customized/expected;
      input = ./customized/input;
    in
    doCompare "customized" expected (mkDummySrc {
      src = input;
      extraDummyScript = ''
        cp ${input}/extra-custom-file.txt $out
        echo 'another additional file' >$out/another-custom-file.txt
      '';
    });
in
linkFarmFromDrvs "cleanCargoToml" (lib.flatten [
  (cmpDummySrc "single" ./single)
  (cmpDummySrc "single-alt" ./single-alt)
  (cmpDummySrc "workspace" ./workspace)

  customizedDummy
])
