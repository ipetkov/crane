{ downloadCargoPackageFromGit
, lib
, pkgsBuildBuild
}:

let
  inherit (pkgsBuildBuild)
    runCommandLocal;

  inherit (builtins)
    any
    attrNames
    filter
    hashString
    head
    isString
    length
    listToAttrs
    placeholder
    split;

  inherit (lib)
    concatMapStrings
    concatStrings
    concatStringsSep
    escapeShellArg
    groupBy
    hasPrefix
    last
    mapAttrs'
    mapAttrsToList
    nameValuePair
    removePrefix;

  knownGitParams = [ "branch" "rev" "tag" ];
  hash = hashString "sha256";
in
{ lockPackages
, outputHashes ? { }
}:
let
  parseGitUrl = p:
    let
      lockUrl = removePrefix "git+" p.source;
      revSplit = split "#" (removePrefix "git+" lockUrl);
      # uniquely identifies the repo in terms of what cargo can address via
      # source replacement (e.g. the url along with any branch/tag/rev).
      id = head revSplit;
      # NB: this is distict from the `rev` query param which may show up
      # if the dependency is explicitly listed with a `rev` value.
      lockedRev = if 3 == length revSplit then last revSplit else
      throw ''
        Cargo.lock is missing a locked revision for ${p.name}@${p.version}.
        you can try to resolve this by running `cargo update -p ${lockUrl}#${p.name}@${p.version}`
      '';

      querySplit = split "\\?" (head revSplit);
      git = head querySplit;

      queryParamSplit = filter
        (qp: (isString qp) && any (p: hasPrefix p qp) knownGitParams)
        (split "&" (last querySplit));
      extractedParams = listToAttrs (map
        (qp:
          let
            kvSplit = (split "=" qp);
          in
          nameValuePair (head kvSplit) (last kvSplit)
        )
        queryParamSplit
      );
    in
    extractedParams // {
      inherit git id lockedRev;
    };

  # Local crates will show up in the lock file with no checksum/source
  lockedPackagesFromGit = filter
    (p: hasPrefix "git" (p.source or ""))
    lockPackages;
  lockedGitGroups = groupBy (p: p.id) (map
    (p: (parseGitUrl p) // { package = p; })
    lockedPackagesFromGit
  );

  sources = mapAttrs'
    (id: ps:
      let
        p = head ps;
        ref =
          if p ? tag then "refs/tags/${p.tag}"
          else if p ? branch then "refs/heads/${p.branch}"
          else null;

        extractedPackages = downloadCargoPackageFromGit {
          inherit (p) git;
          inherit ref;
          rev = p.lockedRev;
          sha256 = outputHashes.${p.package.source} or (lib.warnIf
            (outputHashes != { })
            "No output hash provided for ${p.package.source}"
            null
          );
        };

        # NB: we filter out any crates NOT in the lock file
        # as the repo could have other crates we don't need
        # (e.g. testing crates which might not even build properly)
        # https://github.com/ipetkov/crane/issues/60
        linkPsInLock = concatStringsSep "\n" (map
          (p:
            let
              name = escapeShellArg p.package.name;
              version = escapeShellArg p.package.version;
              vendoredName = "${name}-${version}";
            in
            "ln -s ${extractedPackages}/${vendoredName} $out/${vendoredName}"
          )
          ps
        );
      in
      nameValuePair (hash id) (runCommandLocal "linkLockedDeps" { } ''
        mkdir -p $out
        ${linkPsInLock}
      '')
    )
    lockedGitGroups;

  configLocalSources = concatMapStrings
    (hashedId: ''
      [source.nix-sources-${hashedId}]
      directory = "${placeholder "out"}/${hashedId}"
    '')
    (attrNames sources);

  configReplaceGitSources = mapAttrsToList
    (_hashedId: ps:
      let
        p = head ps;
        extractAttr = attr:
          if p ? ${attr} then ''
            ${attr} = "${p.${attr}}"
          '' else "";
        sourceValues = concatMapStrings extractAttr ([ "git" ] ++ knownGitParams);
      in
      ''
        [source."${p.id}"]
        replace-with = "nix-sources-${hash p.id}"
        ${sourceValues}
      ''
    )
    lockedGitGroups;
in
{
  inherit sources;
  config = configLocalSources + (concatStrings configReplaceGitSources);
}
