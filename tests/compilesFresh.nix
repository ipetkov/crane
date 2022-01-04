{ buildDepsOnly
, buildWithCargo
, jq
}:

src: expected: args:
let
  runCargoAndCheckFreshness = cmd: ''
    cargo ${cmd} --workspace --release --message-format json-diagnostic-short ${args.cargoExtraArgs or ""} >${cmd}out

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
buildWithCargo (args // {
  inherit src;
  doCopyTargetToOutput = false;

  # NB: explicit call here so that the buildDepsOnly call
  # doesn't inherit our build commands
  cargoArtifacts = buildDepsOnly (args // { inherit src; });

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
