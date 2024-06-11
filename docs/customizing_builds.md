## Customizing builds

All derivations, whether they are configured through `buildPackage`,
`cargoBuild`, or even `mkCargoDerivation`, eventually delegate to
[`mkDerivation` which is defined by
nixpkgs](https://nixos.org/manual/nixpkgs/unstable/#ssec-stdenv-dependencies).

At its heart, `mkDerivation` builds up a big `bash` script which is executed by
the builder. Inputs are added to the execution `$PATH`, libraries are added to
include paths, and all other variables are set as shell variables. But these
scripts also come with a small framework for [running various different
phases](https://nixos.org/manual/nixpkgs/unstable/#sec-stdenv-phases). Many of
these phases also come with their own _hooks_ which are shell functions which
can be subscribed to execute before and/or after a particular phase has run.

Although build phases and their hooks allow for easily extending and customizing
the build instructions for a particular derivation, it can become difficult to
identify exactly where a bit of logic should execute. The following are a good
set of resources to consult when in doubt:

1. The [nixpkgs
   manual](https://nixos.org/manual/nixpkgs/unstable/#sec-stdenv-phases) for
   describing the default set of build phases and their hooks
1. The [crane API reference](./API.md) for additional hooks it introduces
1. Setting `NIX_DEBUG` to a non-zero value will cause the builder to print out
   various variables and commands it will run (increasing values will increase
   the verbosity).
1. When all else fails [source for the generic build
   scripts](https://github.com/NixOS/nixpkgs/blob/master/pkgs/stdenv/generic/setup.sh)
   themselves can be useful

All that out of the way, here's a quick example of how to use the build phases
and hooks to customize a particular build:

```nix
craneLib.buildPackage {
  src = craneLib.cleanCargoSource ./.;

  # Define a list of function names to execute before the `configurePhase` runs
  preConfigurePhases = [
    "foo"
    "bar"
  ];

  # Define the functions themselves
  foo = ''
    # double the amount of rust test threads we can use
    # Note that crane will set these defaults as a `postPatchHook` which
    # should have already run by the time the preConfigurePhases are called
    export RUST_TEST_THREADS=$((RUST_TEST_THREADS * 2))
  '';

  bar = ''
    # decrement by one test thread if running in release mode
    if [[ "${CARGO_PROFILE}" == "release" ]]; then
      export RUST_TEST_THREADS=$((RUST_TEST_THREADS - 2))
    fi
  '';

  # Lastly, add postInstall to install additional items after
  # the default installPhase has run and installed the package binaries
  postInstall = ''
    echo "hello world" > $out/hello.txt
    # also install the README.md for good measure
    cp README.md $out/
  '';
}
```
