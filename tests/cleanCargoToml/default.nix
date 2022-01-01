{ cleanCargoToml
, runCommand
, writeTOML
}:

path:
let
  cleaned = cleanCargoToml {
    cargoToml = path + /Cargo.toml;
  };
  cleanedToml = writeTOML "cleaned.toml" cleaned;
  expected = path + /expected.toml;
in
runCommand "compare" { } ''
  diff ${expected} ${cleanedToml}
  touch $out
''
