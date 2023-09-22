{ cleanCargoToml
, lib
, linkFarmFromDrvs
, remarshal
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

      # 23.05 has remarshal 0.14 which sorts keys by default
      # starting with version 0.16 ordering is preserved unless
      # --sort-keys is specified
      sortKeys = lib.optionalString
        (lib.strings.versionAtLeast remarshal.version "0.16.0")
        "--sort-keys";
    in
    runCommand "compare-${name}" { } ''
      function reformat {
        ${remarshal}/bin/remarshal ${sortKeys} -i "$1" --of toml
      }

      diff <(reformat ${expected}) <(reformat ${cleanedToml})
      touch $out
    '';
in
linkFarmFromDrvs "cleanCargoToml" [
  (cmpCleanCargoToml "barebones" ./barebones)
  (cmpCleanCargoToml "complex" ./complex)
]
