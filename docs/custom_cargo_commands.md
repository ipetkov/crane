## Custom cargo commands

Although it is possible to customize exactly what build commands and flags are
used by the provided functions like `buildPackage`, or `cargoBuild`, sometimes
it is useful to encapsulate a cargo invocation that crane does not know about.
Doing so allows that helper function to be used across different crates, or even
different Nix flakes without having to duplicate the logic in multiple build
definitions.

`mkCargoDerivation` allows building such extensions. Below is a short example to
illustrate the approach. The [reference](./API.md#libmkcargoderivation) also
explores the inputs and behavior of `mkCargoDerivation` in greater depth.

```nix
{ pkgs, craneLib }:

# Let's assume we want to add a helper for a fictitious `cargo awesome` command
let
  cargoAwesome = {
    cargoArtifacts,
    cargoAwesomeExtraArgs ? "", # Arguments that are generally useful default
    cargoExtraArgs ? "" # Other cargo-general flags (e.g. for features or targets)
  }@origArgs: let
    # Clean the original arguments for good hygiene (i.e. so the flags specific
    # to this helper don't pollute the environment variables of the derivation)
    args = builtins.removeAttrs origArgs [
      "cargoAwesomeExtraArgs"
      "cargoExtraArgs"
    ];
  in
  craneLib.mkCargoDerivation (args // {
    # Additional overrides we want to explicitly set in this helper

    # Require the caller to specify cargoArtifacts we can use
    inherit cargoArtifacts;

    # A suffix name used by the derivation, useful for logging
    pnameSuffix = "-awesome";

    # Set the cargo command we will use and pass through the flags
    buildPhaseCargoCommand = "cargo awesome ${cargoExtraArgs} ${cargoAwesomeExtraArgs}";

    # Append the `cargo-awesome` package to the nativeBuildInputs set by the
    # caller (or default to an empty list if none were set)
    nativeBuildInputs = (args.nativeBuildInputs or [ ]) ++ [ pkgs.cargo-awesome ];
  });
in
cargoAwesome {
  src = craneLib.cleanCargoSource (craneLib.path ./.);
}
```
