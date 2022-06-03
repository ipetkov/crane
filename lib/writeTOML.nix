# NB: ideally this should just be `remarshal` but it appears to cause an infinite loop when building
# against the release-22.05 branch, so using this as a workaround for now
{ pkgsBuildBuild
, runCommand
}:

name: contents: runCommand name
{
  contents = builtins.toJSON contents;
  passAsFile = [ "contents" ];
  nativeBuildInputs = [ pkgsBuildBuild.remarshal ];
} ''
  remarshal -i $contentsPath -if json -of toml -o $out
''
