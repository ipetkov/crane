{ cargoBuild
}:

{ cargoArtifacts
, cargoDocExtraArgs ? "--no-deps"
, cargoExtraArgs ? ""
, ...
}@origArgs:
let
  args = (builtins.removeAttrs origArgs [ "cargoDocExtraArgs" ]);
in
cargoBuild (args // {
  pnameSuffix = "-doc";

  cargoBuildCommand = "cargoWithProfile doc";
  cargoExtraArgs = "${cargoExtraArgs} ${cargoDocExtraArgs}";

  doCheck = false; # We don't need to run tests to build docs
})
