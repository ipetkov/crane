{ downloadCargoPackage
, lib
, pkgsBuildBuild
}:

let
  inherit (pkgsBuildBuild)
    runCommandLocal;

  inherit (builtins)
    attrNames
    concatStringsSep
    filter
    hasAttr
    hashString
    head
    length
    mapAttrs
    placeholder
    readFile;

  inherit (lib)
    concatMapStrings
    concatStrings
    escapeShellArg
    flatten
    groupBy
    hasPrefix
    mapAttrs'
    mapAttrsToList
    nameValuePair;

  inherit (lib.lists) unique;

  hash = hashString "sha256";

  hasRegistryProtocolPrefix = s: hasPrefix "registry+" s || hasPrefix "sparse+" s;
in
{ cargoConfigs ? [ ]
, lockPackages
, overrideVendorCargoPackage ? _: drv: drv
, ...
}@args:
let
  # Local crates will show up in the lock file with no checksum/source,
  # so should filter them out without trying to download them
  lockedPackagesFromRegistry = filter
    (p: p ? checksum && hasRegistryProtocolPrefix (p.source or ""))
    lockPackages;
  lockedRegistryGroups = groupBy (p: p.source) lockedPackagesFromRegistry;

  vendorCrate = p: overrideVendorCargoPackage p (downloadCargoPackage p);
  vendorSingleRegistry = packages: runCommandLocal "vendor-registry" { } ''
    mkdir -p $out
    ${concatMapStrings (p: ''
      ln -s ${escapeShellArg (vendorCrate p)} $out/${escapeShellArg "${p.name}-${p.version}"}
    '') packages}
  '';

  parsedCargoConfigTomls = map (p: builtins.fromTOML (readFile p)) cargoConfigs;
  allCargoRegistries = flatten (map (c: c.registries or [ ]) parsedCargoConfigTomls);
  allCargoRegistryPairs = flatten (map (mapAttrsToList (name: value: { inherit name value; })) allCargoRegistries);
  allCargoRegistryPairsWithIndex = filter (r: r ? value.index) allCargoRegistryPairs;
  configuredRegistries = mapAttrs (_: map (r: r.value.index)) (groupBy (x: x.name) allCargoRegistryPairsWithIndex);

  # Append the default crates.io registry, but allow it to be overridden
  registries = {
    "crates-io" = [ "https://github.com/rust-lang/crates.io-index" ];
  } // (
    if args ? registries
    then mapAttrs (_: val: [ val ]) args.registries
    else configuredRegistries
  );

  sources = mapAttrs'
    (url: packages: nameValuePair (hash url) (vendorSingleRegistry packages))
    lockedRegistryGroups;

  configLocalSources = concatMapStrings
    (hashedUrl: ''
      [source.nix-sources-${hashedUrl}]
      directory = "${placeholder "out"}/${hashedUrl}"
    '')
    (attrNames sources);

  # e.g. hasSparse x if either has sparse+x, or x starts with sparse+ and has x.
  hasRegistryWithProtocol = (lrg: protocol: u:
    (hasAttr "${protocol}+${u}" lrg) || ((lib.hasPrefix protocol u) && (hasAttr u lrg))
  );
  hasSparseRegistry = hasRegistryWithProtocol lockedRegistryGroups "sparse";
  hasLegacyRegistry = hasRegistryWithProtocol lockedRegistryGroups "registry";

  hasRegistry = (u: (hasSparseRegistry u) || (hasLegacyRegistry u));

  configReplaceRegistries = mapAttrsToList
    (name: urls:
      let
        actuallyConfigured = unique (filter hasRegistry urls);
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
          prefixedUrl = if hasRegistryProtocolPrefix url then url else "registry+${url}";
          hashed = hash prefixedUrl;
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
