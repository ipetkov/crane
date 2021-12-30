{ cleanCargoToml
, runCommand
, writeTOML
}:

let
  cleaned = cleanCargoToml {
    cargoToml = ./Cargo.toml;
  };
  cleanedToml = runCommand "replaced.toml" { } ''
    sed 's!/nix/store/[a-z0-9]\+-!/nix/store/!' \
      ${writeTOML "cleaned.toml" cleaned} >$out
  '';
in
runCommand "compare" { } ''
  diff ${./expected.toml} ${cleanedToml}
  touch $out
''
