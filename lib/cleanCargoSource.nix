{ filterCargoSources
, internalCrateNameForCleanSource
, lib
}:

src: lib.fileset.toSource {
  root = src;

  # Filter out empty directories by converting back and forth from a file set
  fileset = lib.fileset.fromSource (lib.cleanSourceWith {
    # Apply the default source cleaning from nixpkgs
    src = lib.cleanSource src;

    # Then add our own filter on top
    filter = filterCargoSources;

    name = internalCrateNameForCleanSource src;
  });
}
