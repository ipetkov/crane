{ runCommandLocal
}:

{ name
, version
, git
, rev
, ...
}@args:
let
  repo = builtins.fetchGit {
    inherit rev;
    url = git;
    submodules = true;
  };
in
runCommandLocal "cargo-git-${name}-${version}" { } ''
  cp -r ${repo} $out
  chmod +w $out
  echo '{"files":{}, "package":null}' > $out/.cargo-checksum.json
''
