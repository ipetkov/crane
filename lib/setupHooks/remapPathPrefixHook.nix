{
  lib,
  makeSetupHook,
  stdenv,
}:
makeSetupHook {
  name = "remapPathPrefixHook";
  substitutions = {
    storeDir = builtins.storeDir;

    # Unfortunately, we cannot support automatic path remapping on Darwin. The remap paths option
    # requires absolute paths (since rustc will basically do a blind substitution). On Linux builds,
    # each derivation is chrooted to `/build/{name-of-src}` which ends up being the same string for
    # both the real and the deps-only derivations. On Darwin, however, this ends up being
    # `/nix/var/nix/builds/{name-of-derivation}` which *is* different between the main and deps-only
    # derivations. Since this value ends up in CARGO_BUILD_RUSTFLAGS, it effectively will lead to
    # cache invalidation when the real derivation runs if the values differ.
    #
    # Moreover, we can't "just" replace the bytes ourselves since there's no guarantee that the
    # original build path is the same length as the un-neutered store path. Thus we'll noop this for
    # now on Darwin builders and leave it up to the caller to handle path remap if needed...
    isDarwin = lib.optionalString stdenv.buildPlatform.isDarwin /* bash */ ''
      echo 'automatic path remapping not supported on Darwin'
      return 0
    '';
  };
} ./remapPathPrefixHook.sh
