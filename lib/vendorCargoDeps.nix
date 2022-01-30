{ downloadCargoPackage
, findCargoFiles
, fromTOML
, lib
, runCommandLocal
}:

args:
let
  inherit (builtins)
    attrNames
    concatStringsSep
    filter
    groupBy
    hasAttr
    hashString
    head
    length
    placeholder
    mapAttrs
    pathExists
    readFile
    toJSON;

  inherit (lib)
    concatMapStrings
    concatStrings
    escapeShellArg
    flatten
    hasPrefix
    hasSuffix
    mapAttrsToList;

  src = args.src or (throw ''
    unable to find `src` attribute. consider one of the following:
    - set `cargoVendorDir = vendorCargoDeps { cargoLock = ./some/path/to/Cargo.lock; }`
    - set `cargoVendorDir = vendorCargoDeps { src = ./src/containing/cargo/lock/file; }`
    - set `cargoVendorDir = null` to skip vendoring altogether
  '');

  cargoLock = args.cargoLock or (src + /Cargo.lock);
  cargoLockContents = args.cargoLockContents or (
    if pathExists cargoLock
    then readFile cargoLock
    else
      throw ''
        unable to find Cargo.lock at ${src}. please ensure one of the following:
        - a Cargo.lock exists at the root of the source directory of the derivation
        - set `cargoVendorDir = vendorCargoDeps { cargoLock = ./some/path/to/Cargo.lock; }`
        - set `cargoVendorDir = vendorCargoDeps { src = ./src/containing/cargo/lock/file; }`
        - set `cargoVendorDir = null` to skip vendoring altogether
      ''
  );

  hash = hashString "sha256";

  lock = fromTOML cargoLockContents;
  lockPackages = lock.package or (throw "Cargo.lock missing [[package]] definitions");

  # Local crates will show up in the lock file with no checksum/source,
  # so should filter them out without trying to download them
  lockedPackagesFromRegistry = filter
    (p: p ? checksum && hasPrefix "registry" (p.source or ""))
    lockPackages;
  lockedRegistryGroups = groupBy (p: p.source) lockedPackagesFromRegistry;

  vendorSingleRegistry = name: packages: ''
    mkdir -p $out/${name}
    pushd $out/${name}
    ${concatMapStrings (p: ''
      ln -s ${escapeShellArg (downloadCargoPackage p)} ${escapeShellArg "${p.name}-${p.version}"}
    '') packages}
    popd
  '';
  vendorRegistries = mapAttrsToList (url: vendorSingleRegistry (hash url)) lockedRegistryGroups;

  cargoConfigs = (findCargoFiles src).cargoConfigs;
  parsedCargoTomls = map (p: fromTOML (readFile p)) cargoConfigs;
  allCargoRegistries = flatten (map (c: c.registries or [ ]) parsedCargoTomls);
  allCargoRegistryPairs = flatten (map (mapAttrsToList (name: value: { inherit name value; })) allCargoRegistries);
  allCargoRegistryPairsWithIndex = filter (r: r ? value.index) allCargoRegistryPairs;
  configuredRegistries = mapAttrs (_: map (r: r.value.index)) (groupBy (x: x.name) allCargoRegistryPairsWithIndex);

  # Append the default crates.io registry, but allow it to be overridden
  registries = {
    "crates-io" = [ "https://github.com/rust-lang/crates.io-index" ];
  } // configuredRegistries;

  # Ensure the vendor derivation builds, even if the crate has no external dependencies
  scriptInit = ''
    mkdir -p $out
    touch $out/config.toml
  '';

  scriptConfigureLocalSources = map
    (url:
      let
        hashed = hash url;
      in
      ''
        cat >>$out/config.toml <<EOF
        [source.nix-sources-${hashed}]
        directory = "${placeholder "out"}/${hashed}"
        EOF
      ''
    )
    (attrNames lockedRegistryGroups);

  scriptReplaceRegistries = mapAttrsToList
    (name: urls:
      let
        actuallyConfigured = filter (u: hasAttr "registry+${u}" lockedRegistryGroups) urls;
        numConfigured = length actuallyConfigured;
      in
      if numConfigured == 0 then ""
      else if numConfigured > 1 then
        throw ''
          there are multiple distinct registries configured with the same name.
          please ensure that each unique registry name is used with exactly one registry url.
          ${name} is used with:
          ${concatStringsSep "\n" urls}
        ''
      else
        let
          url = head actuallyConfigured;
          hashed = hash "registry+${url}";
        in
        ''
          cat >>$out/config.toml <<EOF
          [source.${name}]
          registry = "${url}"
          replace-with = "nix-sources-${hashed}"
          EOF
        ''
    )
    registries;
in
runCommandLocal "vendor-cargo-deps" { } (concatStrings (flatten [
  scriptInit
  vendorRegistries
  scriptConfigureLocalSources
  scriptReplaceRegistries
]))
