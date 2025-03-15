{ lib
, linkFarmFromDrvs
, mkDummySrc
, remarshal
, runCommand
, writeText
}:

let
  doCompare = name: expected: orig_actual:
    let
      actual = runCommand "trim-actual-${name}" { } ''
        cp --recursive ${orig_actual} --no-target-directory $out --no-preserve=mode,ownership
        find $out -name Cargo.toml | xargs sed -i"" 's!/nix/store/[^-]\+-dummy\(Build\)\?.rs!cranespecific-dummy.rs!'
      '';

      # 23.05 has remarshal 0.14 which sorts keys by default
      # starting with version 0.16 ordering is preserved unless
      # --sort-keys is specified
      sortKeys = lib.optionalString
        (lib.strings.versionAtLeast remarshal.version "0.16.0")
        "--sort-keys";
    in
    runCommand "compare-${name}" { } ''
      echo ${expected} ${actual}
      cp -r --no-preserve=ownership,mode ${expected} ./expected
      cp -r --no-preserve=ownership,mode ${actual} ./actual

      find ./expected ./actual \
        -name Cargo.toml \
        -exec mv '{}' '{}.bak' \; \
        -exec ${remarshal}/bin/remarshal ${sortKeys} --if toml -i '{}.bak' --of toml -o '{}' \;
      find ./expected ./actual -name Cargo.toml.bak -delete

      diff -r ./expected ./actual
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
        #![feature(no_core, lang_items)]
        #[no_std]
        #[no_core]
        // #[no_gods]
        // #[no_masters]

        #[no_mangle]
        extern "C" fn main(_: isize, _: *const *const u8) -> isize {
            0
        }
      '';
    });
in
linkFarmFromDrvs "cleanCargoToml" (lib.flatten [
  (cmpDummySrc "single" ./single)
  (cmpDummySrc "single-alt" ./single-alt)
  # https://github.com/ipetkov/crane/issues/753
  (cmpDummySrc "multibin" ./multibin)
  (cmpDummySrc "workspace" ./workspace)
  (cmpDummySrc "workspace-bindeps" ./workspace-bindeps)
  (cmpDummySrc "workspace-inheritance" ./workspace-inheritance)

  customized
  customizedDummyrs

  # https://github.com/ipetkov/crane/issues/768
  (cmpDummySrc "declaredBinWithMainrs" ./declaredBinWithMainrs)
  (cmpDummySrc "declaredBinWithSrcBin" ./declaredBinWithSrcBin)
  (cmpDummySrc "omittedBinWithMainrs" ./omittedBinWithMainrs)
  (cmpDummySrc "omittedBinWithSrcBin" ./omittedBinWithSrcBin)
])
