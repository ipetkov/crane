{ lib
, linkFarmFromDrvs
, mkDummySrc
, runCommand
, writeText
}:

let
  doCompare = name: expected: orig_actual:
    let
      actual = runCommand "trim-actual-${name}" { } ''
        cp --recursive ${orig_actual} --no-target-directory $out --no-preserve=mode,ownership
        find $out -name Cargo.toml | xargs sed -i"" 's!/nix/store/[^-]\+-dummy.rs!cranespecific-dummy.rs!'
      '';
    in
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

  customized =
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

  customizedDummyrs =
    let
      expected = ./custom-dummyrs/expected;
      input = ./custom-dummyrs/input;
    in
    doCompare "customized-dummyrs" expected (mkDummySrc {
      src = input;
      dummyrs = writeText "dummy.rs" ''
        #![feature(no_core, lang_items, start)]
        #[no_std]
        #[no_core]
        // #[no_gods]
        // #[no_masters]

        #[start]
        fn main(_: isize, _: *const *const u8) -> isize {
            0
        }
      '';
    });
in
linkFarmFromDrvs "cleanCargoToml" (lib.flatten [
  (cmpDummySrc "single" ./single)
  (cmpDummySrc "single-alt" ./single-alt)
  (cmpDummySrc "workspace" ./workspace)
  (cmpDummySrc "workspace-bindeps" ./workspace-bindeps)
  (cmpDummySrc "workspace-inheritance" ./workspace-inheritance)

  customized
  customizedDummyrs
])
