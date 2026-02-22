# Regression test for https://github.com/ipetkov/crane/issues/60

{
  buildPackage,
  lib,
  linkFarmFromDrvs,
  runCommand,
  vendorGitDeps,
  outputHashes ? { },
}:

let
  src = ./git-overlapping;
  lock = builtins.fromTOML (builtins.readFile "${src}/Cargo.lock");

  vendoredGit = vendorGitDeps {
    lockPackages = lock.package;
    inherit outputHashes;
  };

  checkSubset = runCommand "vendorGitSubsetAsExpected" { } ''
    cat >expected <<EOF
    futures-io-0.3.32
    futures-sink-0.4.0-alpha.0
    futures-task-0.4.0-alpha.0
    EOF

    ${builtins.concatStringsSep "\n" (
      builtins.map (s: "ls -1 ${lib.escapeShellArg s} >>./actual") (
        builtins.attrValues vendoredGit.sources
      )
    )}

    diff ./expected ./actual
    touch $out
  '';
in
checkSubset
