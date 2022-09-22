{ lib
}:

src:
let
  inherit (lib)
    flatten
    groupBy
    lists
    mapAttrs
    mapAttrsToList;

  # A specialized form of lib.listFilesRecursive except it will only look
  # for Cargo.toml and files in `.cargo/` to keep the intermediate results lean
  listFilesRecursive = parentIsDotCargo: dir: flatten (mapAttrsToList
    (name: type:
      let
        cur = dir + "/${name}";
        isConfig = parentIsDotCargo && (name == "config" || name == "config.toml");
        isOther = !isConfig && parentIsDotCargo;
        isCargoToml = name == "Cargo.toml";
      in
      if type == "directory"
      then listFilesRecursive (name == ".cargo") cur
      else if isCargoToml
      then [{ path = cur; type = "cargoTomls"; }]
      else if isConfig
      then [{ path = cur; type = "cargoConfigs"; }]
      else if isOther
      then [{ path = cur; type = "other"; }]
      else [ ]
    )
    (builtins.readDir dir));

  foundFiles = listFilesRecursive false src;
  grouped = groupBy (x: x.type) foundFiles;
  cleaned = mapAttrs (_: map (y: y.path)) grouped;

  # Ensure we have a well typed result
  default = {
    cargoTomls = [ ];
    cargoConfigs = [ ];
    other = [ ];
  };
in
default // cleaned
