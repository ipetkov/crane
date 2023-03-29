{ internalCrateNameFromCargoToml
, lib
}:

args:
let
  throwMsg = throw ''
    unable to infer crate name and version. please ensure one of the following:
    - a Cargo.toml exists at the root of the source directory of the derivation
    - `cargoToml` is set to a path to the package's Cargo.toml
    - `cargoTomlContents` is set to the contents of the package's Cargo.toml
    - `pname` and `version` are explicitly set 
  '';

  src = args.src or throwMsg;
  cargoToml = args.cargoToml or (args.src + "/Cargo.toml");
  cargoTomlContents = args.cargoTomlContents or (
    if builtins.pathExists cargoToml
    then builtins.readFile cargoToml
    else throwMsg
  );

  toml = builtins.fromTOML cargoTomlContents;

  debugPath =
    if args ? cargoTomlContents
    then "provided Cargo.toml contents"
    else cargoToml;

  traceMsg = tomlName: drvName: placeholder: lib.flip lib.trivial.warn placeholder ''
    crane will use a placeholder value since `${tomlName}` cannot be found in ${debugPath}
    to silence this warning consider one of the following:
    - setting `${drvName} = "...";` in the derivation arguments explicitly
    - setting `package.${tomlName} = "..."` or `workspace.package.${tomlName} = "..."` in the root Cargo.toml
    - explicitly looking up the values from a different Cargo.toml via 
      `craneLib.crateNameFromCargoToml { cargoToml = ./path/to/Cargo.toml; }`
  '';

  internalName = internalCrateNameFromCargoToml toml;
in
{
  pname = internalName.pname or (traceMsg "name" "pname" "cargo-package");
  version = internalName.version or (traceMsg "version" "version" "0.0.1");
}
