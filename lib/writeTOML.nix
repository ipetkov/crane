{ pkgsBuildBuild
}:

let
  inherit (pkgsBuildBuild)
    remarshal
    runCommand;
in
name: contents: runCommand name
{
  contents = builtins.toJSON contents;
  passAsFile = [ "contents" ];
  nativeBuildInputs = [ remarshal ];
} ''
  remarshal -i $contentsPath -if json -of toml -o $out
''
