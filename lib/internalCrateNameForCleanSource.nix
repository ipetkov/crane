{ internalCrateNameFromCargoToml
}:

src:
let
  origSrc =
    if src ? _isLibCleanSourceWith
    then src.origSrc
    else src;

  cargoTomlContents =
    let
      emptyToml = { };
      cargoToml = origSrc + "/Cargo.toml";
      cargoTomlContents = builtins.readFile cargoToml;
      toml = builtins.tryEval (builtins.fromTOML cargoTomlContents);
    in
    if builtins.pathExists cargoToml
    then
      if toml.success then toml.value else emptyToml
    else
      emptyToml;
in
  (internalCrateNameFromCargoToml cargoTomlContents).pname or "source"

