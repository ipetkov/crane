{ buildDepsOnly
, linkFarmFromDrvs
, jq
}:

expectedArg: mkDrv: args:
let
  runCargoAndCheckFreshness = cmd: extra:
    let
      expected =
        if builtins.isAttrs expectedArg then
          expectedArg.${cmd} or ""
        else
          expectedArg;
    in
    ''
      cargo ${cmd} \
        --release \
        --message-format json-diagnostic-short \
        ${extra} \
        ${args.cargoExtraArgs or ""} >${cmd}out

      filter='select(.reason == "compiler-artifact" and .fresh != true) | .target.name'
      builtTargets="$(jq -r "$filter" <${cmd}out | sort -u)"

      # Make sure only the crate needed building
      if [[ "${expected}" != "$builtTargets" ]]; then
        echo for command ${cmd}
        echo expected \""${expected}"\"
        echo but got  \""$builtTargets"\"
        false
      fi
    '';

  drvArgs = installCargoArtifactsMode: mkDrv (args // {
    inherit installCargoArtifactsMode;

    doInstallCargoArtifacts = false;
    doNotPostBuildInstallCargoBinaries = true;

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
  });
in
linkFarmFromDrvs "compiles-fresh" (map drvArgs [
  "use-zstd"
  "use-symlink"
])
