{ cargo-audit
, lib
, mkCargoDerivation
}:

{ advisory-db
, cargoAuditExtraArgs ? "--ignore yanked"
, src
, ...
}@origArgs:
let
  args = builtins.removeAttrs origArgs [
    "cargoAuditExtraArgs"
  ];
in
mkCargoDerivation (args // {
  buildPhaseCargoCommand = "cargo audit -n -d ${advisory-db} ${cargoAuditExtraArgs}";

  src = lib.cleanSourceWith {
    inherit src;
    # Keep all Cargo.lock and audit.toml files in the source in case the caller wants to
    # pass a flag to audit a specific one.
    filter = path: type: type == "directory"
      || lib.hasSuffix "Cargo.lock" path
      || lib.hasSuffix "audit.toml" path;
  };

  cargoArtifacts = null; # Don't need artifacts, just Cargo.lock
  cargoVendorDir = null; # Don't need dependencies either
  doInstallCargoArtifacts = false; # We don't expect to/need to install artifacts
  pnameSuffix = "-audit";

  # Avoid trying to introspect the Cargo.toml file as it won't exist in the
  # filtered source (it also might not exist in the original source either).
  # So just use some placeholders here in case the caller did not set them.
  pname = args.pname or "crate";
  version = args.version or "0.0.0";

  nativeBuildInputs = (args.nativeBuildInputs or [ ]) ++ [ cargo-audit ];
})
