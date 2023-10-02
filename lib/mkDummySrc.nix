{ cleanCargoToml
, findCargoFiles
, lib
, runCommand
, writeText
, writeTOML
}:

{ src
, cargoLock ? null
, extraDummyScript ? ""
, ...
}@args:
let
  inherit (builtins)
    dirOf
    concatStringsSep
    hasAttr
    match
    storeDir;

  inherit (lib)
    last
    optionalString
    recursiveUpdate
    removePrefix;

  inherit (lib.strings) concatStrings;

  # A quick explanation of what is happening here and why it is done in the way
  # that it is:
  #
  # We want to build a dummy version of the project source. The only things that
  # we want to keep are:
  # 1. the Cargo.lock file
  # 2. any .cargo/config.toml files (unaltered)
  # 3. any Cargo.toml files stripped down only the attributes that would affect
  # caching dependencies
  #
  # Any other sources are completely ignored, and so, we want to avoid any of those ignored sources
  # leading to invalidating our caches. Normally if a build script references any data from another
  # derivation, Nix will consider that entire derivation as an input and any changes to it or its
  # inputs would invalidate the consumer. But we can try to get a bit clever:
  #
  # If we "break up" the input source into smaller parts (i.e. only the parts we care about) we can
  # avoid the "false dependency" invalidation. One trick to accomplishing this is by "laundering"
  # the data at evaluation time: we have Nix read the data out, do some TOML transformations, write
  # it to a fresh file, and then have other derivations consume _that result_. The only thing we
  # have to be careful about is stripping away any "context" Nix may be tracking for the input as we
  # work with it: specifically if the `src` input provided by the caller happens to point to a
  # derivation output (e.g. including using an entire flake source like `{ src = self; }`). Nix
  # carries this "context" to any other strings operations which touch the derivation output (e.g.
  # appending path components). In most cases this is the right thing do to since a derivation which
  # consumes any part of another derivation _probably_ needs to be rebuilt if the latter changes,
  # but here we will explicitly strip the context out since we want to break this dependency.
  # This way, adding a comment or editing an ignored field won't lead to rebuilding everything from
  # scratch!
  #
  # The other trick to accomplishing a similar feat (but without rewriting the files at evaluation
  # time) is to use Nix's source filtering. We give Nix some source path and a function, and Nix
  # will create a brand new entry in the store after while asking the function whether each and
  # every file or directory under said path should be kept or not. The result is that only changes
  # to the kept files would result in rebuilding the consumers.
  #
  # Thus to avoid accidental rebuilds, we need to explicitly filter the source to only contain the
  # files we care about (namely, the .cargo/config.toml files and the Cargo.lock file, we're already
  # cleaning up the Cargo.toml files during evaluation). There is one extra hurdle we have to clear:
  # Nix's source filtering operates in a top-down lazy manner. For every directory it encounters it
  # will ask "should this be kept or not?" If the answer is "no" it skips the directory entirely,
  # which is reasonable. The problem is the function won't know what files that directory may or may
  # not contain unless it indicates the directory should be kept. If that happens but the function
  # rejects all other files under the directory, Nix just keeps the (now empty) directory and moves
  # on. This isn't a huge problem, except that adding a new directory _anywhere_ in the flake root
  # would also invalidate everything again.
  #
  # Finally we pull one last trick up our sleeve: we do the filtering in two passes! First, at
  # evaluation time, we walk the input path and look for any interesting files (i.e.
  # .cargo/config.toml and Cargo.lock files) and remember at what paths they appear relative to the
  # input source. Then we run the source filtering and use that information to guide which files are
  # kept. Namely, if the path being filtered is a regular file, we check if its path (relative to
  # the source root) matches one of our interesting files. If the path being filtered is a
  # directory, we check if it happens to be an ancestor for an interesting file (i.e. is a prefix of
  # an interesting file). That way we are left with the smallest possible source needed for our
  # dummy derivation, and we bring any cache invalidation to a minimum. Whew!

  # NB: if the `src` we were provided was filtered, make sure that we crawl the `origSrc`! Otherwise
  # when we try to crawl the source Nix will evaluate the filter(s) fully resulting in a store path
  # whose prefix won't match the paths we observe when we try to clean the source a bit further down
  # (Nix optimizes multiple filters by running them all once against the original source).
  # https://github.com/ipetkov/crane/issues/46
  origSrc =
    if src ? _isLibCleanSourceWith
    then src.origSrc
    else src;

  uncleanSrcBasePath = (toString origSrc) + "/";
  uncleanFiles = findCargoFiles origSrc;

  cargoTomlsBase = uncleanSrcBasePath;
  inherit (uncleanFiles) cargoTomls;

  cleanSrc =
    let
      allUncleanFiles = map
        (p: removePrefix uncleanSrcBasePath (toString p))
        # Allow the default `Cargo.lock` location to be picked up here
        # (if it exists) so it automattically appears in the cleaned source
        (uncleanFiles.cargoConfigs ++ [ "Cargo.lock" ]);
    in
    lib.cleanSourceWith {
      inherit src;
      name = "cleaned-mkDummySrc";
      filter = path: type:
        let
          strippedPath = removePrefix uncleanSrcBasePath path;
          filter = x:
            if type == "directory" then
              lib.hasPrefix strippedPath x
            else
              x == strippedPath;
        in
        lib.any filter allUncleanFiles;
    };

  dummyrs = args.dummyrs or (writeText "dummy.rs" ''
    #![allow(dead_code)]
    #![cfg_attr(any(target_os = "none", target_os = "uefi"), no_std)]
    #![cfg_attr(any(target_os = "none", target_os = "uefi"), no_main)]

    extern crate core;

    #[cfg_attr(any(target_os = "none", target_os = "uefi"), panic_handler)]
    fn panic(_info: &::core::panic::PanicInfo<'_>) -> ! {
        loop {}
    }

    pub fn main() {}
  '');

  cpDummy = prefix: path: ''
    mkdir -p ${prefix}/${dirOf path}
    cp -f ${dummyrs} ${prefix}/${path}
  '';

  copyAndStubCargoTomls = concatStrings (map
    (p:
      let
        # Safety: all the paths here are fully processed/consumed at evaluation time, so it is is
        # safe to throw away any context (to the Nix store) the original path may have carried.
        # Given that we call `cleanSourceWith` earlier, we know that the input `src` must be valid
        # (or else we would have other errors to deal with)
        cargoTomlDest = builtins.unsafeDiscardStringContext (removePrefix cargoTomlsBase (toString p));
        parentDir = "$out/${dirOf cargoTomlDest}";

        # Override the cleaned Cargo.toml with a build script which points to our dummy
        # source. We need a build script present to cache build-dependencies, which can be
        # achieved by dropping a build.rs file in the source directory. Except that is the most
        # common format to use, and cargo appears to use file timestamps to check for changes
        # to the build script, yet nix will strip all timestamps when putting the sources in the
        # store. This results in cargo not realizing that our dummy script and the project's
        # _real_ script are, in fact, different. So we work around this by having the Cargo.toml
        # file point directly to our dummy source in the store.
        # https://github.com/ipetkov/crane/issues/117
        trimmedCargoToml =
          let
            cleanedCargoToml = cleanCargoToml {
              cargoToml = p;
            };
          in
          # Only update if we have a `package` definition, workspaces Cargo.tomls don't need updating
          if cleanedCargoToml ? package then
            recursiveUpdate
              cleanedCargoToml
              {
                package.build = dummyrs;
              }
          else
            cleanedCargoToml;

        safeStubLib =
          if hasAttr "lib" trimmedCargoToml
          then cpDummy parentDir (trimmedCargoToml.lib.path or "src/lib.rs")
          else "";

        safeStubList = attr: defaultPath:
          let
            targetList = trimmedCargoToml.${attr} or [ ];
            paths = map (t: t.path or "${defaultPath}/${t.name}.rs") targetList;
            commands = map (cpDummy parentDir) paths;
          in
          concatStringsSep "\n" commands;
      in
      ''
        mkdir -p ${parentDir}
        cp ${writeTOML "Cargo.toml" trimmedCargoToml} $out/${cargoTomlDest}
      '' + optionalString (trimmedCargoToml ? package) ''
        # To build regular and dev dependencies (cargo build + cargo test)
        ${cpDummy parentDir "src/lib.rs"}
        ${cpDummy parentDir "src/bin/crane-dummy-${trimmedCargoToml.package.name or "no-name"}/main.rs"}

        # Stub all other targets in case they have particular feature combinations
        ${safeStubLib}
        ${safeStubList "bench" "benches"}
        ${safeStubList "bin" "src/bin"}
        ${safeStubList "example" "examples"}
        ${safeStubList "test" "tests"}
      ''
    )
    cargoTomls
  );

  # Since we allow the caller to provide a path to *some* Cargo.lock file
  # we include it in our dummy build only if it was explicitly specified.
  copyCargoLock =
    if cargoLock == null
    then ""
    else "cp ${cargoLock} $out/Cargo.lock";

  # Note that the name we choose for the dummy source output is load bearing:
  # some CMake projects will error out (thinking their caches are invalidated)
  # if their full parent path changes between runs. The default generic builder
  # will unpack sources by stripping their prefix (e.g. to something like
  # `/build/whatever/...`) so by copying the portion of the name after the Nix hash,
  # we can consistently unpack to the same path instead of unpacking to something like
  # `/build/dummy-src/...`).
  sourceName =
    let
      # NB: we just want to get the source's name but not depend on it
      srcStorePath = builtins.unsafeDiscardStringContext (removePrefix storeDir src);
      # NB: skip all potential hash sequences sometimes there can be two!
      # https://github.com/ipetkov/crane/issues/242
      nameWithoutHash = match "/([a-z0-9]{32}-)+(.*)" srcStorePath;
    in
    if (nameWithoutHash == null)
    # Fall back to a static name if the matching fails for any reason
    then "dummy-src"
    else last nameWithoutHash;
in
runCommand sourceName { } ''
  mkdir -p $out
  cp --recursive --no-preserve=mode,ownership ${cleanSrc}/. -t $out
  ${copyCargoLock}
  ${copyAndStubCargoTomls}
  ${extraDummyScript}
''
