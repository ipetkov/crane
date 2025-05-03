## Missing files during `checks` when filtering with filesets

One sanity check if you are running into `NotFound` errors for flake checks, is
to double check that the derivations built in `checks` have the appropriate
sources. Consider the following:

The `checks` attribute, which may have a `my-workspace-nextest` attribute that
runs `cargo-nextest`, for example, by default only needs the `commonArgs` and
`cargoArtifacts` in order to run tests. However, in cases where tests rely on
reading files, the `src` attribute can also be declared so that the files will
be included when the tests are run. This could also be true for checks like
`my-workspace-clippy`, if markdown files are included in rust doc comments.

```nix
checks.my-workspace-nextest =
  let
    workspace.root = ./.;
    # Keep markdown files for doc generation, or compilation if using the
    # `include` rust macro.
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
