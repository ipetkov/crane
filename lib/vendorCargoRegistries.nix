{ downloadCargoPackage
, fromTOML
, lib
, runCommandLocal
}:

{ cargoConfigs
, lockPackages
}:
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
    mapAttrs
    readFile;

  inherit (lib)
    concatMapStrings
    concatStrings
    escapeShellArg
    flatten
    hasPrefix
    mapAttrs'
    mapAttrsToList
    nameValuePair;

  hash = hashString "sha256";

  # Local crates will show up in the lock file with no checksum/source,
  # so should filter them out without trying to download them
  lockedPackagesFromRegistry = filter
    (p: p ? checksum && hasPrefix "registry" (p.source or ""))
    lockPackages;
  lockedRegistryGroups = groupBy (p: p.source) lockedPackagesFromRegistry;

  vendorSingleRegistry = packages: runCommandLocal "vendor-registry" { } ''
    mkdir -p $out
    ${concatMapStrings (p: ''
      ln -s ${escapeShellArg (downloadCargoPackage p)} $out/${escapeShellArg "${p.name}-${p.version}"}
    '') packages}
  '';

  parsedCargoTomls = map (p: fromTOML (readFile p)) cargoConfigs;
  allCargoRegistries = flatten (map (c: c.registries or [ ]) parsedCargoTomls);
  allCargoRegistryPairs = flatten (map (mapAttrsToList (name: value: { inherit name value; })) allCargoRegistries);
  allCargoRegistryPairsWithIndex = filter (r: r ? value.index) allCargoRegistryPairs;
  configuredRegistries = mapAttrs (_: map (r: r.value.index)) (groupBy (x: x.name) allCargoRegistryPairsWithIndex);

  # Append the default crates.io registry, but allow it to be overridden
  registries = {
    "crates-io" = [ "https://github.com/rust-lang/crates.io-index" ];
  } // configuredRegistries;

  sources = mapAttrs'
    (url: packages: nameValuePair (hash url) (vendorSingleRegistry packages))
    lockedRegistryGroups;

  configLocalSources = concatMapStrings
    (hashedUrl: ''
      [source.nix-sources-${hashedUrl}]
      directory = "${sources.${hashedUrl}}"
    '')
    (attrNames sources);

  configReplaceRegistries = mapAttrsToList
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
          [source.${name}]
          registry = "${url}"
          replace-with = "nix-sources-${hashed}"
        ''
    )
    registries;
in
{
  inherit sources;

  config = configLocalSources + (concatStrings configReplaceRegistries);
}
