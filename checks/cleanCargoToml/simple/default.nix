{ cleanCargoToml
, runCommand
, writeTOML
}:

let
  cleaned = cleanCargoToml {
    cargoToml = ./Cargo.toml;
  };
  cleanedToml = writeTOML "cleaned.toml" cleaned;
in
runCommand "compare" { } ''
  diff ${./expected.toml} ${cleanedToml}
  touch $out
''
