{
  lib,
}:

let
  # See ./cargoTomlAggressive.nix for the fields intentionally retained with explanations.
  # This should be the complement of that list.

  pathsToRemovePerTarget = target: [
    # https://doc.rust-lang.org/cargo/reference/cargo-targets.html#configuring-a-target
    # Additional package attributes which are expressly kept in
    # (but listed here for audit purposes)
    # "crate-type"        # some tools may try to inspect crate types (e.g. wasm-pack), retain the
    #                     # definition to honor the project structure
    # "edition"           # Influences cargo behavior
    # "harness"           # Controls how tests are compiled and run, which might have implications
    #                     # on additional scripts which try to run the tests during buildDepsOnly
    # "name"              # let cargo manage targets/collisions/etc.
    # "path"              # maintain project structure
    # "proc-macro"        # If we have a proc-macro dependency in the workspace, rustc may try to
    #                     # compile `proc-macro2` for the target system
    [target "test"]
    [target "doctest"]
    [target "bench"]
    [target "doc"]
    [target "plugin"]
    [target "required-features"] # only affects selection of a target, does not actually enable any features
    [target "required_features"]
  ];

  # https://doc.rust-lang.org/cargo/reference/manifest.html
  pathsToRemove = [
    ["badges"] # Badges to display on a registry, not relevant for build
    ["lints"]  # Only applied to local sources, which we need to rebuild anyway

    # https://doc.rust-lang.org/cargo/reference/manifest.html#the-package-section
    # Additional package attributes which are expressly kept in
    # (but listed here for audit purposes)
    # "edition"      # Influences cargo behavior
    # "name"         # Required
    # "resolver"     # Influences cargo behavior when edition != 2021
    # "version"      # Required
    # "workspace"    # Keep project structure as is
    ["package" "authors"]
    ["package" "autobenches"]
    ["package" "autobins"]
    ["package" "autoexamples"]
    ["package" "autotests"]
    ["package" "build"]
    ["package" "categories"]
    ["package" "default-run"]
    ["package" "default_run"]
    ["package" "description"]
    ["package" "documentation"]
    ["package" "exclude"]
    ["package" "homepage"]
    ["package" "include"]
    ["package" "keywords"]
    ["package" "license-file"]
    ["package" "license_file"]
    ["package" "license"]
    ["package" "links"]
    ["package" "metadata"]
    ["package" "publish"]
    ["package" "readme"]
    ["package" "repository"]
    ["package" "rust-version"]
    ["package" "rust_version"]

    # https://doc.rust-lang.org/cargo/reference/workspaces.html
    # Additional package attributes which are expressly kept in
    # (but listed here for audit purposes)
    # "default-members"
    # "dependencies"
    # "exclude"
    # "members"
    # "package"
    # "resolver"
    ["workspace" "lints"]    # Only applied to local sources, which we need to rebuild anyway
    ["workspace" "metadata"] # Metadata generally not relevant for build except for specific tools
  ]
  ++ (pathsToRemovePerTarget "lib")
  ++ (pathsToRemovePerTarget "bin")
  ++ (pathsToRemovePerTarget "example")
  ++ (pathsToRemovePerTarget "test")
  ++ (pathsToRemovePerTarget "bench");

  cargoTomlConservative = path: !builtins.any (p: lib.lists.hasPrefix p path) pathsToRemove;
in
cargoTomlConservative
