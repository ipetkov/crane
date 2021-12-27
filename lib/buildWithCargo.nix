{ cargo
, configureCargoVendoredDepsHook
, lib
, stdenv
}:

args@{ nativeBuildInputs ? [ ], ... }:
stdenv.mkDerivation (args // {
  nativeBuildInputs = nativeBuildInputs ++ [
    cargo
    configureCargoVendoredDepsHook
  ];

  buildPhase = ''
    cargo check --release
  '';

  installPhase = ''
    touch $out
  '';
})
