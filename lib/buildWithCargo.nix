{ cargo
, configureCargoCommonVarsHook
, configureCargoVendoredDepsHook
, copyCargoTargetToOutputHook
, lib
, stdenv
}:

{ doCopyTarget ? true
, nativeBuildInputs ? [ ]
, outputs ? [ "out" ]
, ...
}@args:
stdenv.mkDerivation (args // {
  inherit
    doCopyTarget;

  nativeBuildInputs = nativeBuildInputs ++ [
    cargo
    configureCargoCommonVarsHook
    configureCargoVendoredDepsHook
    copyCargoTargetToOutputHook
  ];

  outputs = outputs ++ lib.optional doCopyTarget "target";

  buildPhase = ''
    cargo check --release
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    runHook postInstall
  '';
})
