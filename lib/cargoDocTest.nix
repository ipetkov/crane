{
  mkCargoDerivation,
}:

{
  cargoArtifacts,
  cargoExtraArgs ? "--locked",
  cargoTestExtraArgs ? "",
  ...
}@origArgs:
let
  args = (
    builtins.removeAttrs origArgs [
      "cargoExtraArgs"
      "cargoTestExtraArgs"
    ]
  );
in
mkCargoDerivation (
  args
  // {
    inherit cargoArtifacts;
    doCheck = args.doCheck or true;

    pnameSuffix = "-doctest";
    buildPhaseCargoCommand = "";
    checkPhaseCargoCommand = "cargoWithProfile test --doc ${cargoExtraArgs} ${cargoTestExtraArgs}";

    # Load bearing prepend here, in case the caller sets `preConfigure = "no newline";`
    # we don't want to get a syntax error here (given how these are concatenated)
    preConfigure = ''
      if [[ -z "''${doCheck:-}" ]]; then
        echo '#################################################'
        echo '##                                             ##'
        echo '## doCheck is not set, doc tests will not run! ##'
        echo '##                                             ##'
        echo '#################################################'
      fi
    ''
    + (args.preConfigure or "");
  }
)
