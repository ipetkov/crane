{ fromTOML }:

{ src ? null
, cargoToml ? src + /Cargo.toml
, cargoTomlContents ? builtins.readFile cargoToml
, ...
}:

let
  toml = fromTOML cargoTomlContents;
  p = toml.package;
in
{
  inherit (p) version;
  pname = p.name;
}
