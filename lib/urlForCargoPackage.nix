{}:

# TODO: handle git/private registries
{ name
, version
, source
, ...
}: "https://crates.io/api/v1/crates/${name}/${version}/download"
