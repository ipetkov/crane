{ buildPackage
, cargoBuild
, compilesFresh
, lib
, linkFarmFromDrvs
, runCommand
}:

let
  mkTests = { pname, cargoExtraArgs, runResult }:
    let
      crate = buildPackage {
        inherit cargoExtraArgs pname;
        src = ./features;
      };
    in
    [
      crate

      (compilesFresh "features" cargoBuild {
        inherit cargoExtraArgs;
        src = ./features;
        pname = "${pname}CompilesFresh";
      })

      (runCommand "${pname}Run" { } ''
        [[ "hello${runResult}" == "$(${crate}/bin/features)" ]]
        touch $out
      '')
    ];

  tests = [
    (mkTests {
      pname = "default";
      cargoExtraArgs = "";
      runResult = "";
    })

    (mkTests {
      pname = "foo";
      cargoExtraArgs = "--features foo";
      runResult = "\nfoo";
    })

    (mkTests {
      pname = "bar";
      cargoExtraArgs = "--features bar";
      runResult = "\nbar";
    })

    (mkTests {
      pname = "fooBar";
      cargoExtraArgs = "--features 'foo bar'";
      runResult = "\nfoo\nbar";
    })

    (mkTests {
      pname = "all";
      cargoExtraArgs = "--all-features";
      runResult = "\nfoo\nbar";
    })
  ];
in
linkFarmFromDrvs "features" (lib.flatten tests)
