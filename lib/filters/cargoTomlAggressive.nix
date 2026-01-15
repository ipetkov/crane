{
  lib,
}:

let
  pathsToKeepPerTarget = target: [
    # https://doc.rust-lang.org/cargo/reference/cargo-targets.html#configuring-a-target
    [target "edition"]    # Influences cargo behavior
    [target "path"]       # maintain project structure
    [target "name"]       # let cargo manage targets/collisions/etc.
    [target "crate-type"] # some tools may try to inspect crate types (e.g. wasm-pack), retain the
                          # definition to honor the project structure
    [target "crate_type"]
    [target "proc-macro"] # If we have a proc-macro dependency in the workspace, rustc may try to
                          # compile `proc-macro2` for the target system
    [target "proc_macro"]
    [target "harness"]    # Controls how tests are compiled and run, which might have implications
                          # on additional scripts which try to run the tests during buildDepsOnly
  ];

  # https://doc.rust-lang.org/cargo/reference/manifest.html
  pathsToKeep = [
    ["build-dependencies"] # We want to build and cache these
    ["build_dependencies"]
    ["cargo-features"]     # Just in case some special depencency-related features are needed
    ["cargo_features"]
    ["dependencies"]       # We want build and cache these
    ["dev-dependencies"]   # We want to build and cache these
    ["dev_dependencies"]
    ["features"]           # Keep this as is, some deps may be compiled with different feature combinations
    ["patch"]              # Configures sources as the project wants
    ["profile"]            # This could influence how dependencies are built/optimized
    ["replace"]            # (deprecated) configures sources as the project wants
    ["target"]             # We want to build and cache these
    # https://doc.rust-lang.org/cargo/reference/manifest.html#the-package-section
    ["package" "edition"]    # Influences cargo behavior
    ["package" "name"]       # Required
    ["package" "resolver"]   # Influences cargo behavior when edition != 2021
    ["package" "version"]    # Required
    ["package" "workspace"]  # Keep project structure as is
    # https://doc.rust-lang.org/cargo/reference/workspaces.html
    ["workspace" "default-members"] # Keep project structure as is
    ["workspace" "default_members"]
    ["workspace" "exclude"]         # Keep project structure as is
    ["workspace" "dependencies"]    # We want to build and cache these
    ["workspace" "members"]         # Keep project structure as is
    ["workspace" "package"]
    ["workspace" "resolver"]        # Influences cargo behavior
  ]
  ++ (pathsToKeepPerTarget "lib")
  ++ (pathsToKeepPerTarget "bin")
  ++ (pathsToKeepPerTarget "example")
  ++ (pathsToKeepPerTarget "test")
  ++ (pathsToKeepPerTarget "bench");

  cargoTomlAggressive = path: builtins.any (lib.lists.hasPrefix path) pathsToKeep;
in
cargoTomlAggressive
