{ fromTOML }:

args:
let
  src = args.src or (throw ''
    unable to infer crate name and version. Please make sure the src directory
    contains a valid Cargo.toml file, or consider setting a derivation name explicitly
  '');

  cargoToml = args.cargoToml or (args.src + /Cargo.toml);
  cargoTomlContents = args.cargoTomlContents or (builtins.readFile cargoToml);

  toml = fromTOML cargoTomlContents;
in
{
  pname = toml.package.name or "cargo-package";
  version = toml.package.version or "unknown";
}
