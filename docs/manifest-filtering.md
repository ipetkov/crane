## Cargo.toml manifest filtering

As described in [Source filtering](./source-filtering.md), it is important to
filter the source files used in a Nix build to reduce unnecessary rebuilds.

`craneLib.mkDummySrc`, which is used for `craneLib.buildDepsOnly`, takes this
to the extreme by only including:
1. the `Cargo.lock` file
1. any `.cargo/config.toml` files
1. any `Cargo.toml` files
to ensure that the deps are only rebuilt when really necessary.

However, the `Cargo.toml` manifests can still include a lot of fields which are
irrelevant to dependency resolution, such as documentation links, authorship
information, and so on. To avoid rebuilds due to changes in these fields `crane`
further filters the manifests to only include the fields relevant to dependency
resolution using `craneLib.cleanCargoToml`.

It is possible to customize this filter using `craneLib.mkDummySrc`'s
`cargoManifestFilter` argument. `crane` provides two filters out of the box,
which you can use as-is or compose with your own filters:
- `craneLib.filters.cargoTomlDiscardlist`: omits a predefined list of irrelevant
  fields from the manifests. It keeps any unknown fields. (Default)
- `craneLib.filters.cargoTomlRetainlist`: only keeps a predefined list of
  relevant fields in the manifests. It omits any unknown fields.

To use these in `craneLib.buildDepsOnly`, you can do the following:

```nix
let
  src = craneLib.path ./.;
in
craneLib.buildDepsOnly {
    # other arguments ...
    dummySrc = craneLib.mkDummySrc {
      inherit src;
      cargoManifestFilter = craneLib.filters.cargoTomlRetainlist;
    };
}
```

The filters might omit fields that are actually relevant to your project, for
example, if you are using custom tools beyond `cargo`. In that case, you may
want to compose your own filter on top of them to retain those:

```nix
let
  src = craneLib.path ./.;
  # keep all workspace.metadata.my-tool.* fields
  cargoTomlMyTool = path:
    lib.lists.hasPrefix path ["workspace" "metadata" "my-tool"];
  cargoTomlFilter = path:
    cargoTomlMyTool path ||
    craneLib.filters.cargoTomlRetainlist path;
in
craneLib.mkDummySrc {
  inherit src;
  cargoManifestFilter = cargoTomlFilter;
};
```

Additionally you can also remove further fields:

```nix
let
  src = craneLib.path ./.;
  # also remove the package.version field (and any fields nested beneath it)
  cargoTomlStripVersion = path:
    !lib.lists.hasPrefix ["package" "version"] path;
  cargoTomlFilter = path:
    cargoTomlStripVersion path &&
    craneLib.filters.cargoTomlRetainlist path;
in
craneLib.mkDummySrc {
  inherit src;
  cargoManifestFilter = cargoTomlFilter;
};
```

### `cargoTomlDiscardlist` vs `cargoTomlRetainlist`

`craneLib.filters.cargoTomlRetainlist` is stricuter and will result in less
rebuilds, but it comes with the following caveats:
- It will omit any unknown fields, which may be relevant if you are using
  custom tools beyond `cargo`. You can include those fields by composing your
  own filter on top of it, as shown above.
- If you add a field to your `Cargo.toml` which was just recently added to
  the manifest specification, you need to keep your `crane` version up to date
  to ensure that the field is included in the retainlist. With
  `cargoTomlDiscardlist` this is not an issue, as unknown fields are kept by
  default.
