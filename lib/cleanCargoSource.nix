{ filterCargoSources
, lib
}:

src: lib.cleanSourceWith {
  # Apply the default source cleaning from nixpkgs
  src = lib.cleanSource src;

  # Then add our own filter on top
  filter = filterCargoSources;
}
