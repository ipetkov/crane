{
  pkgsBuildBuild,
}:

let
  inherit (pkgsBuildBuild)
    yj
    runCommand
    ;
in
name: contents:
runCommand name
  {
    contents = builtins.toJSON contents;
    passAsFile = [ "contents" ];
    nativeBuildInputs = [ yj ];
  }
  ''
    cat $contentsPath | yj -jt > $out
  ''
