{ buildDepsOnly
, cargoBuild
, jq
}:

expected: mkDrv: args:
let
  runCargoAndCheckFreshness = cmd: extra: ''
    cargo ${cmd} \
      --release \
      --message-format json-diagnostic-short \
      ${extra} \
      ${args.cargoExtraArgs or ""} >${cmd}out

    filter='select(.reason == "compiler-artifact" and .fresh != true) | .target.name'
    builtTargets="$(jq -r "$filter" <${cmd}out | sort -u)"

    # Make sure only the crate needed building
    if [[ "${expected}" != "$builtTargets" ]]; then
      echo expected \""${expected}"\"
      echo but got  \""$builtTargets"\"
      false
    fi
  '';
in
mkDrv (args // {
  doInstallCargoArtifacts = false;

  # NB: explicit call here so that the buildDepsOnly call
  # doesn't inherit our build commands
  cargoArtifacts = buildDepsOnly args;

  nativeBuildInputs = [ jq ];

  buildPhase = ''
    runHook preBuild

    ${runCargoAndCheckFreshness "check" ""}
    ${runCargoAndCheckFreshness "build" ""}

    runHook postBuild
  '';

  checkPhase = ''
    runHook preCheck

    ${runCargoAndCheckFreshness "test" "--no-run"}

    runHook postCheck
  '';

  installPhase = ''
    touch $out
  '';
})
