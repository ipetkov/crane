{ cargo
, configureCargoCommonVarsHook
, configureCargoVendoredDepsHook
, copyCargoTargetToOutputHook
, lib
, stdenv
}:

{ doCopyTarget ? true
, doCopyTargetToSeparateOutput ? doCopyTarget
, nativeBuildInputs ? [ ]
, outputs ? [ "out" ]
, ...
}@args:
stdenv.mkDerivation (args // {
  inherit
    doCopyTarget
    doCopyTargetToSeparateOutput;

  nativeBuildInputs = nativeBuildInputs ++ [
    cargo
    configureCargoCommonVarsHook
    configureCargoVendoredDepsHook
    copyCargoTargetToOutputHook
  ];

  outputs = outputs ++ lib.optional (doCopyTarget && doCopyTargetToSeparateOutput) "target";

  buildPhase = ''
    cargo check --release
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    runHook postInstall
  '';
})
