{ buildDepsOnly
, buildWithCargo
, jq
}:

{ src, ... }@args:
let
  runCargoAndCheckFreshness = cmd: ''
    cargo ${cmd} --workspace --release --message-format json-diagnostic-short >${cmd}out

    filter='select(.reason == "compiler-artifact" and .fresh != true) | .target.name'
    builtTargets="$(jq -r "$filter" <${cmd}out)"

    # Make sure only the crate needed building
    if [[ "simple" != "$builtTargets" ]]; then
      echo unexpected built targets: $builtTargets
      false
    fi
  '';
in
buildWithCargo (args // {
  inherit src;
  doCopyTargetToOutput = false;

  cargoArtifacts = (buildDepsOnly args).target;

  nativeBuildInputs = [ jq ];

  buildPhase = ''
    runHook preBuild

    ${runCargoAndCheckFreshness "check"}
    ${runCargoAndCheckFreshness "build"}

    runHook postBuild
  '';

    checkPhase = ''
      runHook preCheck

      ${runCargoAndCheckFreshness "test"}

      runHook postCheck
    '';

    installPhase = ''
      touch $out
    '';
})
