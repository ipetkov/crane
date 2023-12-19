## I see the `pyo3` crate constantly rebuilding

The `pyo3` crate uses checks `$PYO3_PYTHON` for a path to the `python` binary it
should use during the build. If this environment variable is not set, `pyo3`
will look for whatever version of `python` is on the `$PATH`, which
unfortunately results in the crate being rebuilt when `$PATH` changes (i.e.
whenever the cargo artifacts are used in a derivation which may have different
build inputs).

The way to remedy this is to explicitly set `PYO3_PYTHON` to point to the
version of `python` that will be used by the derivation:

```nix
let
  chosenPython = pkgs.python3;
in
craneLib.buildPackage {
  env.PYO3_PYTHON = "${chosenPython}/bin/python";
  nativeBuildInputs = [
    chosenPython
  ];

  # etc...
}
```
