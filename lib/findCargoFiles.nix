{
  lib,
}:

let
  inherit (lib)
    flatten
    flip
    groupBy
    mapAttrs
    mapAttrsToList
    optionals
    ;
  defaultFilter = _: _: true;

  # A specialized form of lib.listFilesRecursive except it will only look
  # for Cargo.toml and config.toml files to keep the intermediate results lean
  listFilesRecursive =
    filter: parentIsDotCargo: dir:
    flatten (
      flip mapAttrsToList (builtins.readDir dir) (
        name: type:
        let
          cur = builtins.unsafeDiscardStringContext ((toString dir) + "/${name}");

          isConfig = parentIsDotCargo && (name == "config.toml" || name == "config");
          isCargoToml = name == "Cargo.toml";
        in
        # NB: manually apply any cleanSourceWith filtering here to avoid surprises
        # in accidentally finding files that were meant to be excluded
        # https://github.com/ipetkov/crane/issues/985
        optionals (filter cur type) (
          if type == "directory" then
            listFilesRecursive filter (name == ".cargo") cur
          else if isCargoToml then
            [
              {
                path = cur;
                type = "cargoTomls";
              }
            ]
          else if isConfig then
            [
              {
                path = cur;
                type = "cargoConfigs";
              }
            ]
          else
            [ ]
        )
      )
    );

  # Ensure we have a well typed result
  default = {
    cargoTomls = [ ];
    cargoConfigs = [ ];
  };
in
src:
let
  isCleanSourceWith = src._isLibCleanSourceWith or false;
  origSrc = if isCleanSourceWith then src.origSrc or src else src;
  filter = if isCleanSourceWith then src.filter or defaultFilter else defaultFilter;

  foundFiles = listFilesRecursive filter false origSrc;
  grouped = groupBy (x: x.type) foundFiles;
  cleaned = mapAttrs (_: map (y: y.path)) grouped;
in
default // cleaned
