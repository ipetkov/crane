{ writeText
, remarshal
, runCommand
, pkgsBuildBuild
}:

name: contents: runCommand name
{
  contents = builtins.toJSON contents;
  passAsFile = [ "contents" ];
  nativeBuildInputs = [ pkgsBuildBuild.remarshal ];
} ''
  remarshal -i $contentsPath -if json -of toml -o $out
''
