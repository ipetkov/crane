## I'm trying to build another cargo project from source which has no lock file

First consider if there is a release of this project available _with_ a lock
file as it may be simpler and more consistent to use the exact dependencies
published by the project itself. Projects published on crates.io always come
with a lock file and `nixpkgs` has a `fetchCrate` fetcher which pulls straight
from crates.io.

If that is not an option, the next best thing is to generate your own
`Cargo.lock` file and pass it in as an override by setting `cargoLock =
./path/to/Cargo.lock`. If you are calling `buildDepsOnly` or `vendorCargoDeps`
directly the value must be passed there; otherwise you can pass it into
`buildPackage` or `cargoBuild` and it will automatically passed through.

Note that the `Cargo.lock` file must be accessible _at evaluation time_ for the
dependency vendoring to work, meaning the file cannot be generated within the
same derivation that builds the project. It _may_ come from another derivation,
but it may require enabling IFD if flakes are not used.
