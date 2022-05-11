{ cleanCargoToml
, linkFarmFromDrvs
, runCommand
, writeTOML
}:

let
  cmpCleanCargoToml = name: path:
    let
      cleaned = cleanCargoToml {
        cargoToml = path + "/Cargo.toml";
      };
      cleanedToml = writeTOML "cleaned.toml" cleaned;
      expected = path + "/expected.toml";
    in
    runCommand "compare-${name}" { } ''
      diff ${expected} ${cleanedToml}
      touch $out
    '';
in
linkFarmFromDrvs "cleanCargoToml" [
  (cmpCleanCargoToml "barebones" ./barebones)
  (cmpCleanCargoToml "complex" ./complex)
]
