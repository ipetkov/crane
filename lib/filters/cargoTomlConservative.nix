{
  lib,
}:

let
  # See ./cargoTomlAggressive.nix for the fields intentionally retained with explanations.
  # This should be the complement of that list.

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
  pathsToRemoveIndexPerTarget = {
    test = true;
    doctest = true;
    bench = true;
    doc = true;
    plugin = true;
    # only affects selection of a target, does not actually enable any features
    required-features = true;
    required_features = true;
  };

  # https://doc.rust-lang.org/cargo/reference/manifest.html
  pathsToRemoveIndex = {
    # Badges to display on a registry, not relevant for build
    badges = true;
    # Only applied to local sources, which we need to rebuild anyway
    lints = true;

    # https://doc.rust-lang.org/cargo/reference/manifest.html#the-package-section
    # Additional package attributes which are expressly kept in
    # (but listed here for audit purposes)
    # "edition"      # Influences cargo behavior
    # "name"         # Required
    # "resolver"     # Influences cargo behavior when edition != 2021
    # "version"      # Required
    # "workspace"    # Keep project structure as is
    package = {
      authors = true;
      autobenches = true;
      autobins = true;
      autoexamples = true;
      autotests = true;
      build = true;
      categories = true;
      default-run = true;
      default_run = true;
      description = true;
      documentation = true;
      exclude = true;
      homepage = true;
      include = true;
      keywords = true;
      license-file = true;
      license_file = true;
      license = true;
      links = true;
      metadata = true;
      publish = true;
      readme = true;
      repository = true;
      rust-version = true;
      rust_version = true;
    };

    # https://doc.rust-lang.org/cargo/reference/workspaces.html
    # Additional package attributes which are expressly kept in
    # (but listed here for audit purposes)
    # "default-members"
    # "dependencies"
    # "exclude"
    # "members"
    # "package"
    # "resolver"
    workspace = {
      # Only applied to local sources, which we need to rebuild anyway
      lints = true;
      # Metadata generally not relevant for build except for specific tools
      metadata = true;
    };

    lib = pathsToRemoveIndexPerTarget;
    bin = pathsToRemoveIndexPerTarget;
    example = pathsToRemoveIndexPerTarget;
    test = pathsToRemoveIndexPerTarget;
    bench = pathsToRemoveIndexPerTarget;
  };

  isInIndex =
    index: path:
    if builtins.isBool index then
      index
    else if path == [ ] then
      false
    else
      let
        next = index.${builtins.head path} or null;
      in
      next != null && isInIndex next (builtins.tail path);

  cargoTomlConservative = path: !isInIndex pathsToRemoveIndex path;
in
cargoTomlConservative
