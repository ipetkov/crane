{ cargo
, configureCargoCommonVarsHook
, configureCargoVendoredDepsHook
, lib
, stdenv
}:

args@{ nativeBuildInputs ? [ ], ... }:
stdenv.mkDerivation (args // {
  nativeBuildInputs = nativeBuildInputs ++ [
    cargo
    configureCargoCommonVarsHook
    configureCargoVendoredDepsHook
  ];

  buildPhase = ''
    cargo check --release
  '';

  installPhase = ''
    touch $out
  '';
})
