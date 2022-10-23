{ cargoAudit
, fetchFromGitHub
, linkFarmFromDrvs
, runCommandLocal
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

  simpleWithAuditToml = (auditWith "simple-with-audit-toml" ./simple-with-audit-toml);

  containsAuditTomlInSrc = runCommandLocal "containsAuditTomlInSrc" { } ''
    if [[ -f ${simpleWithAuditToml.src}/.cargo/audit.toml ]]; then
      touch $out
    else
      echo "missing audit.toml file"
      false
    fi
  '';
in
linkFarmFromDrvs "cleanCargoToml" [
  # Check against all different kinds of workspace types to make sure it works
  (auditWith "simple" ./simple)
  (auditWith "simple-git" ./simple-git)

  simpleWithAuditToml
  containsAuditTomlInSrc

  (auditWith "gitRevNoRef" ./gitRevNoRef)
  (auditWith "git-overlapping" ./git-overlapping)

  (auditWith "workspace" ./workspace)
  (auditWith "workspace-git" ./workspace-git)
  (auditWith "workspace-root" ./workspace-root)
]
