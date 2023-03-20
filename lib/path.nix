{ internalCrateNameFromCargoToml
, lib
}:

input:
let
  pathArgs = if lib.isAttrs input then input else { path = input; };

  cargoTomlContents =
    let
      emptyToml = { };
      cargoToml = pathArgs.path + "/Cargo.toml";
      cargoTomlContents = builtins.readFile cargoToml;
      toml = builtins.tryEval (builtins.fromTOML cargoTomlContents);
    in
    if builtins.pathExists cargoToml
    then
      if toml.success then toml.value else emptyToml
    else
      emptyToml;

  name = (internalCrateNameFromCargoToml cargoTomlContents).pname or "source";
in
builtins.path ({ inherit name; } // pathArgs)
