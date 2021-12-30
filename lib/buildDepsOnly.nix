{ buildWithCargo
, crateNameFromCargoToml
, mkDummySrc
}:

args:
let
  crateName = crateNameFromCargoToml args;
  defaults = {
    inherit (crateName) version;
    pname = "${crateName.pname}-deps";

    buildPhase = ''
      runHook preBuild
      cargo check --workspace --release
      cargo build --workspace --release
      runHook postBuild
    '';

    # Don't install anything by default, but let the caller set their own if they wish
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      runHook postInstall
    '';
  };

  forced = {
    # Prevent infinite recursion, we are the root of all artifacts
    cargoArtifacts = null;
    # No point in building this if not for the cargo artifacts
    doCopyTargetToOutput = true;
    src = mkDummySrc args;
  };
in
buildWithCargo (defaults // args // forced)
