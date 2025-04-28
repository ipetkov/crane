## Source filtering

Nix considers that a derivation must be rebuilt whenever any of its inputs
change, including all source files passed into the build. Unfortunately, this
means that changes to any "irrelevant" files (such as the project README) would
end up rebuilding the project even if the final outputs don't actually care
about their contents!

Source filtering is a technique Nix employs that allows for better caching by
programmatically filtering out files which are known to not apply to the build
_before_ the inputs are hashed.

A default source cleaner is available via `craneLib.cleanCargoSource`: it cleans
a source tree to omit things like version control directories as well omit any
non-Rust/non-cargo related files. It can be used like so:

```nix
craneLib.buildPackage {
  # other attributes omitted
  src = craneLib.cleanCargoSource ./.;
}
```

It is possible to customize the filter to use when cleaning the source by
leveraging `craneLib.filterCargoSources`. By default this filter will only keep
files whose names end with `.rs` or `.toml`. Though it is possible to compose it
with other filters, especially if it is necessary to include additional files
which it might otherwise omit:

```nix
let
  # Only keeps markdown files
  markdownFilter = path: _type: builtins.match ".*md$" path != null;
  markdownOrCargo = path: type:
    (markdownFilter path type) || (craneLib.filterCargoSources path type);
in
craneLib.buildPackage {
  # other attributes omitted
  src = lib.cleanSourceWith {
    src = ./.; # The original, unfiltered source
    filter = markdownOrCargo;
    name = "source"; # Be reproducible, regardless of the directory name
  };
}
```

## Fileset filtering

A more composable alternative to source filtering is using [filesets]:

```nix
let
  unfilteredRoot = ./.; # The original, unfiltered source
  src = lib.fileset.toSource {
    root = unfilteredRoot;
    fileset = lib.fileset.unions [
      # Default files from crane (Rust and cargo files)
      (craneLib.fileset.commonCargoSources unfilteredRoot)
      # Also keep any markdown files
      (lib.fileset.fileFilter (file: file.hasExt "md") unfilteredRoot)
      # Example of a folder for images, icons, etc
      (lib.fileset.maybeMissing ./assets)
    ];
  };
in
craneLib.buildPackage {
  # other attributes omitted
  inherit src;
}
```

### Fileset filtering in flake checks

One sanity check if you are running into `NotFound` errors for flake checks, is to double check that the derivations
built in `checks` have the appropriate sources. Consider the following:

The `checks` attribute, which may have a `my-workspace-nextest` attribute that runs `cargo-nextest`, for example,
by default only needs the `commonArgs` and `cargoArtifacts` in order to run tests. However, in cases where tests rely on
reading files, the `src` attribute can also be declared so that the files will be included when the tests are run. 
This could also be true for checks like `my-workspace-clippy`, if markdown files are included in rust doc comments.
```nix
checks.my-workspace-nextest =
  let
    workspace.root = ./.;
    # Keep markdown files for doc generation, or compilation if using the `include` rust macro.
    docSources = from: lib.fileset.fileFilter (file: file.hasExt "md") from;
    # Keep json files for testing.
    testDataSources = from: lib.fileset.fileFilter (file: file.hasExt "json") from;
  in
  craneLib.cargoNextest (buildArgs // {
    inherit cargoArtifacts;
    src = lib.fileset.toSource {
      inherit (workspace) root;
      fileset = lib.fileset.unions [
        ./Cargo.toml
        ./Cargo.lock
        ./src
        (craneLib.fileset.commonCargoSources workspace.root)
        (docSources workspace.root)
        (testDataSources workspace.root)
      ];
    };
    partitions = 1;
    partitionType = "count";
    cargoNextestExtraArgs = "--no-tests=warn";
  });
```

[filesets]: https://nixos.org/manual/nixpkgs/unstable/#sec-functions-library-fileset
