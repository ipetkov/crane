{
  cleanCargoToml,
  filters,
  lib,
  linkFarmFromDrvs,
  remarshal,
  runCommand,
  writeTOML,
}:

let
  cmpCleanCargoToml =
    folderName: path: filterName: filter:
    let
      cleaned = cleanCargoToml {
        cargoToml = path + "/Cargo.toml";
        cleanCargoTomlFilter = filter;
      };
      cleanedToml = writeTOML "cleaned-${folderName}-${filterName}.toml" cleaned;
      expectedPathSpecific = path + "/expected-${filterName}.toml";
      expected =
        if lib.pathExists expectedPathSpecific then expectedPathSpecific else path + "/expected.toml";
    in
    runCommand "compare-${folderName}-${filterName}" { } ''
      function reformat {
        ${remarshal}/bin/remarshal --sort-keys -i "$1" --of toml
      }

      diff <(reformat ${expected}) <(reformat ${cleanedToml})
      touch $out
    '';
  cmpAllFilters =
    name: path:
    lib.mapAttrsToList (filterName: filter: cmpCleanCargoToml name path filterName filter) filters;

  testMatrix = {
    barebones = ./barebones;
    complex = ./complex;
    # https://github.com/ipetkov/crane/issues/610
    complex-underscores = ./complex-underscores;
    # https://github.com/ipetkov/crane/issues/800
    proc-macro = ./proc-macro;
  };
in
linkFarmFromDrvs "cleanCargoToml" (lib.concatLists (lib.mapAttrsToList cmpAllFilters testMatrix))
