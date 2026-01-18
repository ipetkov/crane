{
  filters,
  lib,
}:
let
  # Based on lib.filterAttrsRecursive, but
  # - also processes lists
  # - passes the full path to the filter function
  filterData' =
    pred: path: val:
    if builtins.isAttrs val then
      builtins.listToAttrs (
        builtins.concatMap (
          name:
          let
            v = val.${name};
            p = path ++ [ name ];
          in
          if pred p then [ (lib.nameValuePair name (filterData' pred p v)) ] else [ ]
        ) (builtins.attrNames val)
      )
    else if builtins.isList val then
      # Keep all list elements but filter their contents.
      builtins.map (filterData' pred path) val
    else
      val;
  filterData = pred: val: filterData' pred [ ] val;
in
{
  cargoToml ? throw "either cargoToml or cargoTomlContents must be specified",
  cargoTomlContents ? builtins.readFile cargoToml,
  # ([String] -> Boolean)
  filter ? filters.cargoTomlDefault,
}:
filterData filter (builtins.fromTOML cargoTomlContents)
