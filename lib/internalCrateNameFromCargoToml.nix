{
  lib,
}:

let
  firstNonNull = lib.lists.findFirst lib.isString null;
  wpnDeprecated =
    val: debugPath:
    lib.warnIf (val != null)
      "`workspace.package.name` is deprecated, please use `workspace.metadata.crane.name` in ${debugPath}"
      val;
in
toml: debugPath:
lib.filterAttrs (_: v: v != null) {
  # Now that cargo supports workspace inheritance we attempt to select a name
  # with the following priorities:
  # - choose `[package.metadata.crane.name]` if the value is present and a string
  # - choose `[package.name]` if the value is present and a string
  #   (i.e. it isn't `[package.name] = { workspace = "true" }`)
  # - choose `[workspace.metadata.crane.name]` if the value is present and a string
  # - choose `[workspace.package.name]` if it is present (and a string for good measure)
  # - otherwise, fall back to a placeholder
  pname = firstNonNull [
    (toml.workspace.metadata.crane.name or null)
    (toml.package.metadata.crane.name or null)
    (toml.package.name or null)
    (wpnDeprecated (toml.workspace.package.name or null) debugPath)
  ];

  # Now that cargo supports workspace inheritance we attempt to select a version
  # string with the following priorities:
  # - choose `[workspace.metadta.crane.version]` if present and a string
  # - choose `[package.version]` if the value is present and a string
  #   (i.e. it isn't `[package.version] = { workspace = "true" }`)
  # - choose `[workspace.package.version]` if it is present (and a string for good measure)
  # - otherwise, fall back to a placeholder
  version = firstNonNull [
    (toml.workspace.metadata.crane.version or null)
    (toml.package.version or null)
    (toml.workspace.package.version or null)
  ];
}
