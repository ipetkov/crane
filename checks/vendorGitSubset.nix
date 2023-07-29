# Regression test for https://github.com/ipetkov/crane/issues/60

{ buildPackage
, lib
, linkFarmFromDrvs
, runCommand
, vendorGitDeps
, outputHashes ? { }
}:

let
  src = ./git-repo-with-many-crates;
  lock = builtins.fromTOML (builtins.readFile "${src}/Cargo.lock");

  # Ensure crate still builds
  crate = buildPackage {
    inherit src;
  };

  vendoredGit = vendorGitDeps {
    lockPackages = lock.package;
    inherit outputHashes;
  };

  checkSubset = runCommand "vendorGitSubsetAsExpected" { } ''
    cat >expected <<EOF
    tokio-1.20.4
    tokio-macros-1.8.0
    tokio-util-0.7.3
    EOF

    ${builtins.concatStringsSep "\n" (builtins.map
      (s: "ls -1 ${lib.escapeShellArg s} >>./actual")
      (builtins.attrValues vendoredGit.sources)
    )}

    diff ./expected ./actual
    touch $out
  '';
in
linkFarmFromDrvs "vendorGitSubset" [
  checkSubset
  crate
]
