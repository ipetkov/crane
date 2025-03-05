{}:

let
  # https://doc.rust-lang.org/cargo/reference/manifest.html#the-package-section
  cleanPackage = package: removeAttrs package [
    "authors"
    "autobenches"
    "autobins"
    "autoexamples"
    "autotests"
    "build"
    "categories"
    "default-run"
    "default_run"
    "description"
    "documentation"
    "exclude"
    "homepage"
    "include"
    "keywords"
    "license-file"
    "license_file"
    "license"
    "links"
    "metadata"
    "publish"
    "readme"
    "repository"
    "rust-version"
    "rust_version"

    # Additional package attributes which are expressly kept in
    # (but listed here for audit purposes)
    # "edition"      # Influences cargo behavior
    # "name"         # Required
    # "resolver"     # Influences cargo behavior when edition != 2021
    # "version"      # Required
    # "workspace"    # Keep project structure as is
  ];

  # https://doc.rust-lang.org/cargo/reference/cargo-targets.html#configuring-a-target
  cleanTargetCommon = target: removeAttrs target [
    "test"
    "doctest"
    "bench"
    "doc"
    "plugin"
    "harness"
    "required-features" # only affects selection of a target, does not actually enable any features
    "required_features" # only affects selection of a target, does not actually enable any features

    # Additional package attributes which are expressly kept in
    # (but listed here for audit purposes)
    # "edition"           # Influences cargo behavior
    # "path"              # maintain project structure
    # "name"              # let cargo manage targets/collisions/etc.
    # "crate-type"        # some tools may try to inspect crate types (e.g. wasm-pack), retain the
    #                     # definition to honor the project structure
    # "proc-macro"        # If we have a proc-macro dependency in the workspace, rustc may try to
    #                     # compile `proc-macro2` for the target system
  ];

  cleanWorkspace = workspace: removeAttrs workspace [
    "lints"
    "metadata"

    # Additional package attributes which are expressly kept in
    # (but listed here for audit purposes)
    # "default-members"
    # "exclude"
    # "dependencies"
    # "members"
    # "package"
    # "resolver"
  ];

  # https://doc.rust-lang.org/cargo/reference/manifest.html
  cleanCargoToml = parsed:
    let
      safeClean = f: attr:
        if builtins.hasAttr attr parsed
        then { ${attr} = f (builtins.getAttr attr parsed); }
        else { };

      safeCleanList = f: safeClean (map f);

      topLevelCleaned = removeAttrs parsed [
        "badges" # Badges to display on a registry.
        "lints" # Only applied to local sources, which we need to rebuild anyway

        # Top level attributes intentionally left in place:
        # "build-dependencies" # we want to build and cache these
        # "cargo-features"     # just in case some special depencency-related features are needed
        # "dependencies"       # we want build and cache these
        # "dev-dependencies"   # we want to build and cache these
        # "features"           # keep this as is, some deps may be compiled with different feature combinations
        # "patch"              # configures sources as the project wants
        # "profile"            # this could influence how dependencies are built/optimized
        # "replace"            # (deprecated) configures sources as the project wants
        # "target"             # we want to build and cache these
      ];
    in
    topLevelCleaned
    // (safeClean cleanPackage "package")
    // (safeClean cleanTargetCommon "lib")
    // (safeClean cleanWorkspace "workspace")
    // (safeCleanList cleanTargetCommon "bench")
    // (safeCleanList cleanTargetCommon "bin")
    // (safeCleanList cleanTargetCommon "example")
    // (safeCleanList cleanTargetCommon "test");
in
{ cargoToml ? throw "either cargoToml or cargoTomlContents must be specified"
, cargoTomlContents ? builtins.readFile cargoToml
}:
cleanCargoToml (builtins.fromTOML cargoTomlContents)
