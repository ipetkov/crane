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

[filesets]: https://nixos.org/manual/nixpkgs/unstable/#sec-functions-library-fileset
