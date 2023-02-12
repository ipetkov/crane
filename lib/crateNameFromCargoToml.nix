{ lib
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

  traceMsg = tomlName: drvName: placeholder: lib.trivial.warn
    "crane cannot find ${tomlName} attribute in ${debugPath}, consider setting `${drvName} = \"...\";` explicitly"
    placeholder;
in
{
  # Now that cargo supports workspace inheritance we attempt to select a name
  # with the following priorities:
  # - choose `[package.name]` if the value is present and a string
  #   (i.e. it isn't `[package.name] = { workspace = "true" }`)
  # - choose `[workspace.package.name]` if it is present (and a string for good measure)
  # - otherwise, fall back to a placeholder
  pname =
    let
      packageName = toml.package.name or null;
      workspacePackageName = toml.workspace.package.name or null;
    in
    if lib.isString packageName then packageName
    else if lib.isString workspacePackageName then workspacePackageName
    else traceMsg "name" "pname" "cargo-package";

  # Now that cargo supports workspace inheritance we attempt to select a version
  # string with the following priorities:
  # - choose `[package.version]` if the value is present and a string
  #   (i.e. it isn't `[package.version] = { workspace = "true" }`)
  # - choose `[workspace.package.version]` if it is present (and a string for good measure)
  # - otherwise, fall back to a placeholder
  version =
    let
      packageVersion = toml.package.version or null;
      workspacePackageVersion = toml.workspace.package.version or null;
    in
    if lib.isString packageVersion then packageVersion
    else if lib.isString workspacePackageVersion then workspacePackageVersion
    else traceMsg "version" "version" "0.0.1";
}
