{ lib
}:

args:
let
  src = args.src or (throw ''
    unable to infer crate name and version. Please make sure the src directory
    contains a valid Cargo.toml file, or consider setting a derivation name explicitly
  '');

  cargoToml = args.cargoToml or (args.src + "/Cargo.toml");
  cargoTomlContents = args.cargoTomlContents or (builtins.readFile cargoToml);

  toml = builtins.fromTOML cargoTomlContents;
in
{
  pname = toml.package.name or "cargo-package";

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
    else "0.0.1";
}
