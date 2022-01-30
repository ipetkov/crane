{ cleanCargoToml
, linkFarmFromDrvs
, runCommandLocal
, writeTOML
}:

let
  cmpCleanCargoToml = name: path:
    let
      cleaned = cleanCargoToml {
        cargoToml = path + /Cargo.toml;
      };
      cleanedToml = writeTOML "cleaned.toml" cleaned;
      expected = path + /expected.toml;
    in
    runCommandLocal "compare-${name}" { } ''
      diff ${expected} ${cleanedToml}
      touch $out
    '';
in
linkFarmFromDrvs "cleanCargoToml" [
  (cmpCleanCargoToml "barebones" ./barebones)
  (cmpCleanCargoToml "complex" ./complex)
]
