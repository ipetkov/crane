{ lib
}:

toml:
lib.filterAttrs (_: v: v != null) {
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
    else null;

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
    else null;
}
