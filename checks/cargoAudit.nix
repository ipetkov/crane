{ cargoAudit
, fetchFromGitHub
, lib
, linkFarmFromDrvs
}:

let
  auditWith = pname: src: cargoAudit {
    inherit src pname;
    advisory-db = fetchFromGitHub {
      owner = "rustsec";
      repo = "advisory-db";
      rev = "36df8a4efc6f2da4ccc7ced0d431136f473b2001";
      sha256 = "sha256-9eSrCrsSNyl79JMH7LrlCpn9a8lYJ01daZNxUDBKMEo=";
    };
  };
in
linkFarmFromDrvs "cleanCargoToml" [
  # Check against all different kinds of workspace types to make sure it works
  (auditWith "simple" ./simple)
  (auditWith "simple-git" ./simple-git)

  (auditWith "gitRevNoRef" ./gitRevNoRef)
  (auditWith "git-overlapping" ./git-overlapping)

  (auditWith "workspace" ./workspace)
  (auditWith "workspace-git" ./workspace-git)
  (auditWith "workspace-root" ./workspace-root)
]
