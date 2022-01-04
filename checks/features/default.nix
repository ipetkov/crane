{ buildPackage
, compilesFresh
, lib
, linkFarmFromDrvs
, runCommand
}:

let
  mkTests = { name, cargoExtraArgs, runResult }:
    let
      crate = buildPackage {
        inherit cargoExtraArgs name;
        src = ./features;
      };
    in
    [
      crate

      (compilesFresh ./features "features" {
        inherit cargoExtraArgs;
        name = "${name}CompilesFresh";
      })

      (runCommand "${name}Run" { } ''
        [[ "hello${runResult}" == "$(${crate}/bin/features)" ]]
        touch $out
      '')
    ];

  tests = [
    (mkTests {
      name = "default";
      cargoExtraArgs = "";
      runResult = "";
    })

    (mkTests {
      name = "foo";
      cargoExtraArgs = "--features foo";
      runResult = "\nfoo";
    })

    (mkTests {
      name = "bar";
      cargoExtraArgs = "--features bar";
      runResult = "\nbar";
    })

    (mkTests {
      name = "fooBar";
      cargoExtraArgs = "--features 'foo bar'";
      runResult = "\nfoo\nbar";
    })

    (mkTests {
      name = "all";
      cargoExtraArgs = "--all-features";
      runResult = "\nfoo\nbar";
    })
  ];
in
linkFarmFromDrvs "features" (lib.flatten tests)
