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
  src = craneLib.cleanCargoSource (craneLib.path ./.);
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
    src = craneLib.path ./.; # The original, unfiltered source
    filter = markdownOrCargo;
  };
}
```
