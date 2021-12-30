{ fromTOML
, toTOML
, writeText
}:

let
  dummyLib = writeText "lib.rs" "#[test] fn it_works() {}";
  dummyMain = writeText "main.rs" "fn main() {}";

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
    "description"
    "documentation"
    "edition"
    "exclude"
    "homepage"
    "include"
    "keywords"
    "license-file"
    "license"
    "links"
    "metadata"
    "publish"
    "readme"
    "repository"
    "resolver"
    "rust-version"

    # Additional package attributes which are expressly kept in
    # (but listed here for audit purposes)
    # "name"         # The name of the package.
    # "version"      # The version of the package.
    # "workspace"    # Path to the workspace for the package.
  ];

  # https://doc.rust-lang.org/cargo/reference/cargo-targets.html#configuring-a-target
  cleanTargetCommon = pathReplacement: target:
    let
      cleanedCommon =
        removeAttrs target [
          "test"
          "doctest"
          "bench"
          "doc"
          "edition"
          "plugin"
          "proc-macro"
          "harness"
          "crate-type"

          # Additional package attributes which are expressly kept in
          # (but listed here for audit purposes)
          # "name"              # let cargo manage targets/collisions/etc.
          # "required-features" # influences dependency feature combinations
        ];
    in
    cleanedCommon // { path = builtins.toString pathReplacement; };

  # https://doc.rust-lang.org/cargo/reference/manifest.html
  cleanCargoToml = parsed:
    let
      topLevelCleaned = removeAttrs parsed [
        "badges" # Badges to display on a registry.

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
        # "workspace"          # keep the workspace hierarchy as the project wants
      ];

      recursivelyCleaned = {
        package = cleanPackage (parsed.package or { });
        lib = cleanTargetCommon dummyLib (parsed.lib or { });

        bench = map (cleanTargetCommon dummyLib) (parsed.bench or [ ]);
        bin = map (cleanTargetCommon dummyMain) (parsed.bin or [ ]);
        example = map (cleanTargetCommon dummyLib) (parsed.example or [ ]);
        test = map (cleanTargetCommon dummyLib) (parsed.test or [ ]);
      };
    in
    topLevelCleaned // recursivelyCleaned;
in
{ cargoToml ? throw "either cargoToml or cargoTomlContents must be specified"
, cargoTomlContents ? builtins.readFile cargoToml
}:
cleanCargoToml (fromTOML cargoTomlContents)
