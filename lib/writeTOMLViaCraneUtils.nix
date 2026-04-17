{
  craneUtils,
  pkgsBuildBuild,
}:

let
  inherit (pkgsBuildBuild) runCommand;
in
name: contents:
runCommand name
  {
    contents = builtins.toJSON contents;
    passAsFile = [ "contents" ];
    depsBuildBuild = [ craneUtils ];
  }
  ''
    crane-json2toml <"$contentsPath" >"$out"
  ''
