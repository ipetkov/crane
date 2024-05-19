# API Documentation

## `mkLib`

`mkLib :: pkgs -> set`

Creates a `lib` instance bound to the specified (and instantiated) `pkgs` set.
This is a convenience escape hatch in case you want to use your own custom
instantiation of nixpkgs with the overlays you may need.

```nix
mkLib (import inputs.nixpkgs { system = "armv7l-linux"; })
```

Note that if you wish to override a particular package without having to overlay
it across all of nixpkgs, consider using `overrideScope`:

```nix
(mkLib pkgs).overrideScope (final: prev: {
  cargo-tarpaulin = myCustomCargoTarpaulinVersion;
})
```

To overlay an entire rust toolchain (e.g. `cargo`, `rustc`, `clippy`, `rustfmt`,
etc.) consider using `overrideToolchain`.

## `craneLib`

`craneLib` represents an instantiated value crated by `mkLib` above.

### `craneLib.appendCrateRegistries`

`appendCrateRegistries :: [registry mapping] -> new lib`

Creates a new `lib` instance which will make additional registries available for
use when downloading crate sources. Each entry can be defined using:
* `registryFromDownloadUrl`: if you know the exact `dl` URL as defined in the
  registry's `config.json` file
* `registryFromGitIndex`: if you would like the download URL to be inferred from
  the index's source directly.
* `registryFromSparse`: if you would like the download URL to be inferred from
  the index's source directly, and the index is a sparse index.

See the documentation on each function for more specifics.

```nix
newLib = craneLib.appendCrateRegistries [
  (craneLib.registryFromDownloadUrl {
    indexUrl = "https://github.com/rust-lang/crates.io-index";
    dl = "https://static.crates.io/crates";
    fetchurlExtraArgs = {};
  })

  # Or, alternatively
  (craneLib.registryFromGitIndex {
    indexUrl = "https://github.com/Hirevo/alexandrie-index";
    rev = "90df25daf291d402d1ded8c32c23d5e1498c6725";
    fetchurlExtraArgs = {};
  })

  # Or even
  (lib.registryFromSparse {
    url = "https://index.crates.io/";
    sha256 = "d16740883624df970adac38c70e35cf077a2a105faa3862f8f99a65da96b14a3";
  })
];
```

### `craneLib.buildDepsOnly`

`buildDepsOnly :: set -> drv`

Create a derivation which will only build all dependencies of a cargo workspace.

Useful for splitting up cargo projects into two derivations: one which only
builds dependencies and needs to be rebuilt when a Cargo.lock file changes, and
another which inherits the cargo artifacts from the first and (quickly) builds
just the application itself.

The exact cargo commands being run (or the arguments passed into it) can be
easily updated to suit your needs. By default all artifacts from running `cargo
{check,build,test}` will be cached.

In addition to all default and overridden values being set as documented below,
all derivation attributes are delegated to `mkCargoDerivation`, and can be used
to influence its behavior.
* `cargoArtifacts`: set to `null` since this is our entry point for generating
  cargo artifacts
* `doInstallCargoArtifacts`: set to `true`
* `pnameSuffix`: set to `"-deps"`
* `src`: set to the result of `mkDummySrc` after applying the arguments set.
  This ensures that we do not need to rebuild the cargo artifacts derivation
  whenever the application source changes.

#### Optional attributes
* `buildPhaseCargoCommand`: A command to run during the derivation's build
  phase. Pre and post build hooks will automatically be run.
  - Default value: `"${cargoCheckCommand} ${cargoExtraArgs}\n${cargoBuildCommand} ${cargoExtraArgs}"`
* `cargoBuildCommand`: A cargo (build) invocation to run during the derivation's build
  phase
  - Default value: `"cargo build --profile release"`
    * `CARGO_PROFILE` can be set on the derivation to alter which cargo profile
      is selected; setting it to `""` will omit specifying a profile
      altogether.
* `cargoCheckCommand`: A cargo (check) invocation to run during the derivation's build
  phase (in order to cache additional artifacts)
  - Default value: `"cargo check --profile release ${cargoCheckExtraArgs}"`
    * `CARGO_PROFILE` can be set on the derivation to alter which cargo profile
      is selected; setting it to `""` will omit specifying a profile
      altogether.
* `cargoCheckExtraArgs`: additional flags to be passed in the `cargoCheckCommand`
  invocation
  - Default value: `"--all-targets"` if `doCheck` is set to true, `""` otherwise
* `cargoExtraArgs`: additional flags to be passed in the cargo invocation (e.g.
  enabling specific features)
  - Default value: `"--locked"`
* `cargoTestCommand`: A cargo invocation to run during the derivation's check
  phase
  - Default value: `"cargo test --profile release"`
    * `CARGO_PROFILE` can be set on the derivation to alter which cargo profile
      is selected; setting it to `""` will omit specifying a profile
      altogether.
* `cargoTestExtraArgs`: additional flags to be passed in the `cargoTestCommand`
  invocation (e.g. enabling specific tests)
  - Default value: `"--no-run"`
* `cargoVendorDir`: A path (or derivation) of vendored cargo sources which can
  be consumed without network access. Directory structure should basically
  follow the output of `cargo vendor`.
  - Default value: the result of `vendorCargoDeps` after applying the arguments
    set (with the respective default values)
* `checkPhaseCargoCommand`: A command to run during the derivation's check
  phase. Pre and post check hooks will automatically be run.
  - Default value: `"${cargoTestCommand} ${cargoExtraArgs}"`
* `doCheck`: whether the derivation's check phase should be run
  - Default value: `true`
* `dummySrc`: the "dummy" source to use when building this derivation.
  Automatically derived if not passed in
  - Default value: `mkDummySrc args.src`
* `pname`: package name of the derivation
  - Default value: inherited from calling `crateNameFromCargoToml`
* `version`: version of the derivation
  - Default value: inherited from calling `crateNameFromCargoToml`

#### Remove attributes
The following attributes will be removed before being lowered to
`mkCargoDerivation`. If you absolutely need these attributes present as
environment variables during the build, you can bring them back via
`.overrideAttrs`.

* `cargoBuildCommand`
* `cargoCheckCommand`
* `cargoCheckExtraArgs`
* `cargoExtraArgs`
* `cargoTestCommand`
* `cargoTestExtraArgs`
* `dummySrc`
* `outputHashes`
* `outputs`

### `craneLib.buildPackage`

`buildPackage :: set -> drv`

A(n opinionated) version of `mkCargoDerivation` which will install to the output
any binaries which were built by cargo in this invocation. All options
understood by `mkCargoDerivation` apply here as well, with the only difference
being some additional book keeping necessary to log cargo's results and
subsequently install from that log.

Note that only `bin`, `cdylib`, `dylib`, and `staticlib`, targets will be installed by
default (namely `rlib` targets will be ignored), though it is possible to adjust
the behavior by changing the `installPhaseCommand` or registering additional
install hooks.

#### Optional attributes
* `buildPhaseCargoCommand`: A command to run during the derivation's build
  phase. Pre and post build hooks will automatically be run.
  - Default value: `cargoBuildCommand` will be invoked along with
    `cargoExtraArgs` passed in, except cargo's build steps will also be captured
    and written to a log so that it can be used to find the build binaries.
  - Note that the default install hook assumes that the build phase will create
    a log of cargo's build results. If you wish to customize this command
    completely, make sure that cargo is run with `--message-format
    json-render-diagnostics` and the standard output captured and saved to a
    file. The `cargoBuildLog` shell variable should point to this log.
* `cargoArtifacts`: A path (or derivation) which contains an existing cargo
  `target` directory, which will be reused at the start of the derivation.
  Useful for caching incremental cargo builds.
  - Default value: the result of `buildDepsOnly` after applying the arguments
    set (with the respective default values).
  - `installPhase` and `installPhaseCommand` will be removed, and no
    installation hooks will be run
* `cargoBuildCommand`: A cargo invocation to run during the derivation's build
  phase
  - Default value: `"cargo build --profile release"`
    * `CARGO_PROFILE` can be set on the derivation to alter which cargo profile
      is selected; setting it to `""` will omit specifying a profile
      altogether.
* `cargoExtraArgs`: additional flags to be passed in the cargo invocation (e.g.
  enabling specific features)
  - Default value: `"--locked"`
* `cargoTestCommand`: A cargo invocation to run during the derivation's check
  phase
  - Default value: `"cargo test --profile release"`
    * `CARGO_PROFILE` can be set on the derivation to alter which cargo profile
      is selected; setting it to `""` will omit specifying a profile
      altogether.
* `cargoTestExtraArgs`: additional flags to be passed in the `cargoTestCommand`
  invocation (e.g. enabling specific tests)
  - Default value: `""`
* `doCheck`: whether the derivation's check phase should be run
  - Default value: `true`
* `doInstallCargoArtifacts`: controls whether cargo's `target` directory should
  be copied as an output
  - Default value: `false`
* `installPhaseCommand`: the command(s) which are expected to install the
  derivation's outputs.
  - Default value: will look for a cargo build log and install all binary
    targets listed there

#### Remove attributes
The following attributes will be removed before being lowered to
`mkCargoDerivation`. If you absolutely need these attributes present as
environment variables during the build, you can bring them back via
`.overrideAttrs`.

* `cargoBuildCommand`
* `cargoExtraArgs`
* `cargoTestCommand`
* `cargoTestExtraArgs`
* `outputHashes`

#### Native build dependencies and included hooks
The following hooks are automatically added as native build inputs:
* `installFromCargoBuildLogHook`
* `jq`
* `removeReferencesToVendoredSourcesHook`

### `craneLib.buildTrunkPackage`
`buildTrunkPackage :: set -> drv`

Create a derivation which will build a distributable directory for a WASM application.

Except where noted below, all derivation attributes are delegated to
`mkCargoDerivation`, and can be used to influence its behavior.

#### Optional attributes
* `buildPhaseCargoCommand`: A command to run during the derivation's build
  phase. Pre and post build hooks will automatically be run.
  - Default value: `trunk build` will be invoked along with `trunkExtraArgs`,
    `trunkExtraBuildArgs`, and `trunkIndexpath` passed in. If `$CARGO_PROFILE`
    is set to `release` then the `--release` flag will also be set for the build
* `cargoArtifacts`: A path (or derivation) which contains an existing cargo
  `target` directory, which will be reused at the start of the derivation.
  Useful for caching incremental cargo builds.
  - Default value: the result of `buildDepsOnly` after applying the arguments
    set (with the respective default values).
  - `CARGO_BUILD_TARGET` will be set to `"wasm32-unknown-unknown"` if not specified.
  - `doCheck` will be set to `false` if not specified.
  - `installPhase` and `installPhaseCommand` will be removed (in favor of their
    default values provided by `buildDepsOnly`)
* `installPhaseCommand`: the command(s) which are expected to install the
  derivation's outputs.
  - Default value: will install trunk's `dist` output directory
* `trunkExtraArgs` pass additional arguments to `trunk`
  - Default value: `""`
* `trunkExtraBuildArgs` pass additional arguments to `trunk build`
  - Default value: `""`
* `trunkIndexPath` A path to the index.html of your trunk project
  - Default value: `"./index.html"`
* `wasm-bindgen-cli` The package used to satisfy the `wasm-bindgen-cli`
  dependency of `trunk`, the version used here must match the version
  of `wasm-bindgen` in the `Cargo.lock` file of your project *exactly*.
  - Default value: `pkgs.wasm-bindgen-cli`


#### Remove attributes
The following attributes will be removed before being lowered to
`mkCargoDerivation`. If you absolutely need these attributes present as
environment variables during the build, you can bring them back via
`.overrideAttrs`.

* `trunkExtraArgs`
* `trunkExtraBuildArgs`
* `trunkIndexPath`

#### Native build dependencies and included hooks
The following hooks are automatically added as native build inputs:
* `binaryen`
* `dart-sass`
* `trunk`

### `craneLib.cargoAudit`
`cargoAudit :: set -> drv`

Create a derivation which will run a `cargo audit` invocation in a cargo
workspace.

Except where noted below, all derivation attributes are delegated to
`mkCargoDerivation`, and can be used to influence its behavior.
* `buildPhaseCargoCommand` will be set to run `cargo audit -n -d ${advisory-db}` in
  the workspace.
* `cargoArtifacts` will be set to `null` as they are not needed
* `cargoVendorDir` will be set to `null` as it is not needed
* `doInstallCargoArtifacts` is disabled
* `pnameSuffix` will be set to `"-audit"`
* `src` will be filtered to only keep `Cargo.lock` files

#### Required attributes
* `advisory-db`: A path (or derivation) which contains the advisory database
  - It is possible to track the advisory database as a flake input and avoid
    having to manually update hashes or specific revisions to check out
* `src`: The project source to audit, it must contain a `Cargo.lock` file
  - Note that the source will internally be filtered to omit any files besides
    `Cargo.lock`. This avoids having to audit the project again until either the
    advisory database or the dependencies change.

#### Optional attributes
* `cargoAuditExtraArgs`: additional flags to be passed in the cargo-audit invocation
  - Default value: `"--ignore yanked"`
* `pname`: the name of the derivation; will _not_ be introspected from a
  `Cargo.toml` file
  - Default value: `"crate"`
* `version`: the version of the derivation, will _not_ be introspected from a
  `Cargo.toml` file
  - Default value: `"0.0.0"`

#### Native build dependencies
The `cargo-audit` package is automatically appended as a native build input to any
other `nativeBuildInputs` specified by the caller.

#### Remove attributes
The following attributes will be removed before being lowered to
`mkCargoDerivation`. If you absolutely need these attributes present as
environment variables during the build, you can bring them back via
`.overrideAttrs`.
* `cargoAuditExtraArgs`

### `craneLib.cargoDeny`
`cargoDeny :: set -> drv`

Create a derivation which will run a `cargo deny` invocation in a cargo
workspace.

Note that although `cargo deny` can serve as a replacement for `cargo audit`,
`craneLib.cargoDeny` does not expose this functionality because `cargo deny`
requires the full source tree, rather than working from just the `Cargo.lock`
file, meaning it will be re-run when any source file changes, rather than only
when dependencies change.

Except where noted below, all derivation attributes are delegated to
`mkCargoDerivation`, and can be used to influence its behavior.
* `buildPhaseCargoCommand` will be set to run
  `cargo --offline $cargoExtraArgs deny $cargoDenyExtraArgs check
  $cargoDenyChecks` in the workspace.
* `cargoArtifacts` will be set to `null`
* `doInstallCargoArtifacts` will be set to `false`
* `pnameSuffix` will be set to `"-deny"`

#### Optional attributes
* `cargoDenyChecks`: check types to run
  - Default value: `"bans licenses sources"`
* `cargoDenyExtraArgs`: additional flags to be passed in the cargo-deny invocation
  - Default value: `""`
* `cargoExtraArgs`: additional flags to be passed in the cargo invocation
  - Default value: `""`

#### Native build dependencies
The `cargo-deny` package is automatically appended as a native build input to any
other `nativeBuildInputs` specified by the caller.

#### Remove attributes
The following attributes will be removed before being lowered to
`mkCargoDerivation`. If you absolutely need these attributes present as
environment variables during the build, you can bring them back via
`.overrideAttrs`.
* `cargoDenyExtraArgs`
* `cargoExtraArgs`

### `craneLib.cargoBuild`

`cargoBuild :: set -> drv`

Create a derivation which will run a `cargo build` invocation in a cargo
workspace. Consider using `buildPackage` if all you need is to build the
workspace and install the resulting application binaries.

Except where noted below, all derivation attributes are delegated to
`mkCargoDerivation`, and can be used to influence its behavior.
* `buildPhaseCargoCommand` will be set to run `cargo build --profile release` for
  the workspace.
  - `CARGO_PROFILE` can be set on the derivation to alter which cargo profile
    is selected; setting it to `""` will omit specifying a profile
    altogether.
* `pnameSuffix` will be set to `"-build"`

#### Required attributes
* `cargoArtifacts`: A path (or derivation) which contains an existing cargo
  `target` directory, which will be reused at the start of the derivation.
  Useful for caching incremental cargo builds.
  - This can be prepared via `buildDepsOnly`
  - Alternatively, any cargo-based derivation which was built with
    `doInstallCargoArtifacts = true` will work as well

#### Optional attributes
* `cargoExtraArgs`: additional flags to be passed in the cargo invocation (e.g.
  enabling specific features)
  - Default value: `"--locked"`

#### Remove attributes
The following attributes will be removed before being lowered to
`mkCargoDerivation`. If you absolutely need these attributes present as
environment variables during the build, you can bring them back via
`.overrideAttrs`.

* `cargoExtraArgs`

### `craneLib.cargoClippy`

`cargoClippy :: set -> drv`

Create a derivation which will run a `cargo clippy` invocation in a cargo
workspace.

Except where noted below, all derivation attributes are delegated to
`mkCargoDerivation`, and can be used to influence its behavior.
* `buildPhaseCargoCommand` will be set to run `cargo clippy --profile release` for
  the workspace.
  - `CARGO_PROFILE` can be set on the derivation to alter which cargo profile
    is selected; setting it to `""` will omit specifying a profile
    altogether.
* `pnameSuffix` will be set to `"-clippy"`

#### Required attributes
* `cargoArtifacts`: A path (or derivation) which contains an existing cargo
  `target` directory, which will be reused at the start of the derivation.
  Useful for caching incremental cargo builds.
  - This can be prepared via `buildDepsOnly`
  - Alternatively, any cargo-based derivation which was built with
    `doInstallCargoArtifacts = true` will work as well

#### Optional attributes
* `cargoClippyExtraArgs`: additional flags to be passed in the clippy invocation (e.g.
  deny specific lints)
  - Default value: `"--all-targets"`
* `cargoExtraArgs`: additional flags to be passed in the cargo invocation (e.g.
  enabling specific features)
  - Default value: `"--locked"`

#### Native build dependencies
The `clippy` package is automatically appended as a native build input to any
other `nativeBuildInputs` specified by the caller.

#### Remove attributes
The following attributes will be removed before being lowered to
`mkCargoDerivation`. If you absolutely need these attributes present as
environment variables during the build, you can bring them back via
`.overrideAttrs`.
* `cargoClippyExtraArgs`
* `cargoExtraArgs`

### `craneLib.cargoDoc`

`cargoDoc :: set -> drv`

Create a derivation which will run a `cargo doc` invocation in a cargo
workspace.

Except where noted below, all derivation attributes are delegated to
`mkCargoDerivation`, and can be used to influence its behavior.
* `buildPhaseCargoCommand` will be set to run `cargo doc --profile release` for
  the workspace.
  - `CARGO_PROFILE` can be set on the derivation to alter which cargo profile
    is selected; setting it to `""` will omit specifying a profile
    altogether.
* `doInstallCargoArtifacts` will default to `false` if not specified
* `pnameSuffix` will be set to `"-doc"`

#### Required attributes
* `cargoArtifacts`: A path (or derivation) which contains an existing cargo
  `target` directory, which will be reused at the start of the derivation.
  Useful for caching incremental cargo builds.
  - This can be prepared via `buildDepsOnly`
  - Alternatively, any cargo-based derivation which was built with
    `doInstallCargoArtifacts = true` will work as well

#### Optional attributes
* `cargoDocExtraArgs`: additional flags to be passed in the rustdoc invocation (e.g.
  deny specific lints)
  - Default value: `"--no-deps"`
* `cargoExtraArgs`: additional flags to be passed in the cargo invocation (e.g.
  enabling specific features)
  - Default value: `"--locked"`
* `docInstallRoot`: defines the exact directory to install to `$out/share`,
  useful for overriding when compiling different targets. By default will honor
  `$CARGO_TARGET_DIR` (or default to `./target` if not set) and
  `$CARGO_BUILD_TARGET` (if set).
  - Default value: `"${CARGO_TARGET_DIR:-target}/${CARGO_BUILD_TARGET:-}/doc"`

#### Remove attributes
The following attributes will be removed before being lowered to
`mkCargoDerivation`. If you absolutely need these attributes present as
environment variables during the build, you can bring them back via
`.overrideAttrs`.
* `cargoDocExtraArgs`
* `cargoExtraArgs`
* `docInstallRoot`

### `craneLib.cargoFmt`

`cargoFmt :: set -> drv`

Create a derivation which will run a `cargo fmt` invocation in a cargo
workspace.

Except where noted below, all derivation attributes are delegated to
`mkCargoDerivation`, and can be used to influence its behavior.
* `buildPhaseCargoCommand` will be set to run `cargo fmt` (in check mode) in the
  workspace.
* `cargoArtifacts` is disabled/cleared
* `cargoVendorDir` is disabled/cleared
* `pnameSuffix` will be set to `"-fmt"`

#### Optional attributes
* `cargoExtraArgs`: additional flags to be passed in the cargo invocation
  - Default value: `""`
* `rustFmtExtraArgs`: additional flags to be passed in the rustfmt invocation
  - Default value: `""`

#### Native build dependencies
The `rustfmt` package is automatically appended as a native build input to any
other `nativeBuildInputs` specified by the caller.

#### Remove attributes
The following attributes will be removed before being lowered to
`mkCargoDerivation`. If you absolutely need these attributes present as
environment variables during the build, you can bring them back via
`.overrideAttrs`.
* `cargoExtraArgs`
* `rustFmtExtraArgs`

### `craneLib.cargoLlvmCov`

`cargoLlvmCov :: set -> drv`

Create a derivation which will run a `cargo llvm-cov` invocation in a cargo
workspace.

Except where noted below, all derivation attributes are delegated to
`mkCargoDerivation`, and can be used to influence its behavior.
* `buildPhaseCargoCommand` will be set to run `cargo llvm-cov test --release` in
  the workspace.
* `installPhaseCommand` will be set to `""`, as the default settings creates
  a file instead of directory at `$out`.
* `doInstallCargoArtifacts` will be set to `false` for the same reason as
  `installPhaseCommand`
* `pnameSuffix` will be set to `"-llvm-cov"`

#### Required attributes
* `cargoArtifacts`: A path (or derivation) which contains an existing cargo
  `target` directory, which will be reused at the start of the derivation.
  Useful for caching incremental cargo builds.
  - This can be prepared via `buildDepsOnly`
  - Alternatively, any cargo-based derivation which was built with
    `doInstallCargoArtifacts = true` will work as well

#### Optional attributes
* `cargoExtraArgs`: additional flags to be passed in the cargo invocation
  - Default value: `"--locked"`
* `cargoLlvmCovCommand`: cargo-llvm-cov command to run
  - Default value: `"test"`
* `cargoLlvmCovExtraArgs`: additional flags to be passed in the cargo
  llvm-cov invocation
  - Default value: `"--lcov --output-path $out"`

#### Native build dependencies
The `cargo-llvm-cov` package is automatically appended as a native build input to any
other `nativeBuildInputs` specified by the caller.

Note that this would require the `llvm-tools-preview` component for the Rust toolchain,
which you would need to provide yourself using fenix or rust-overlay.

#### Remove attributes
The following attributes will be removed before being lowered to
`mkCargoDerivation`. If you absolutely need these attributes present as
environment variables during the build, you can bring them back via
`.overrideAttrs`.
* `cargoExtraArgs`
* `cargoLlvmCovCommand`
* `cargoLlvmCovExtraArgs`

### `craneLib.cargoNextest`

`cargoNextest :: set -> drv`

Create a derivation which will run a `cargo nextest` invocation in a cargo
workspace.

Except where noted below, all derivation attributes are delegated to
`mkCargoDerivation`, and can be used to influence its behavior.
* `checkPhaseCargoCommand` will be set to run `cargo nextest run --profile release`
  for the workspace.
  - `CARGO_PROFILE` can be set on the derivation to alter which cargo profile
    is selected; setting it to `""` will omit specifying a profile
    altogether.
* `pnameSuffix` will be set to `"-nextest"` and may include partition numbers

#### Required attributes
* `cargoArtifacts`: A path (or derivation) which contains an existing cargo
  `target` directory, which will be reused at the start of the derivation.
  Useful for caching incremental cargo builds.
  - This can be prepared via `buildDepsOnly`
  - Alternatively, any cargo-based derivation which was built with
    `doInstallCargoArtifacts = true` will work as well

#### Optional attributes
* `buildPhaseCargoCommand`, unless specified, will be set to print the nextest version
* `cargoExtraArgs`: additional flags to be passed in the cargo invocation (e.g.
  enabling specific features)
  - Default value: `""`
* `cargoLlvmCovExtraArgs`: additional flags to be passed in the cargo
  llvm-cov invocation
  - Default value: `"--lcov --output-path $out/coverage"`
* `cargoNextestExtraArgs`: additional flags to be passed in the nextest invocation
  (e.g. specifying a profile)
  - Default value: `""`
* `partitions`: The number of separate nextest partitions to run. Useful if the
  test suite takes a long time and can be parallelized across multiple build
  nodes.
  - Default value: `1`
* `partitionType`: The kind of nextest partition to run (e.g. `"count"` or
  `"hash"` based).
  - Default value: `"count"`
* `withLlvmCov`: Whether or not to run nextest through `cargo llvm-cov`
  - Default value: `false`
  - Note that setting `withLlvmCov = true;` is not currently supported if
    `partitions > 1`.

#### Native build dependencies
The `cargo-nextest` package is automatically appended as a native build input to any
other `nativeBuildInputs` specified by the caller.

#### Remove attributes
The following attributes will be removed before being lowered to
`mkCargoDerivation`. If you absolutely need these attributes present as
environment variables during the build, you can bring them back via
`.overrideAttrs`.
* `cargoExtraArgs`
* `cargoLlvmCovExtraArgs`
* `cargoNextestExtraArgs`
* `partitions`
* `partitionType`
* `withLlvmCov`

### `craneLib.cargoTarpaulin`

`cargoTarpaulin :: set -> drv`

Create a derivation which will run a `cargo tarpaulin` invocation in a cargo
workspace.

Except where noted below, all derivation attributes are delegated to
`mkCargoDerivation`, and can be used to influence its behavior.
* `buildPhaseCargoCommand` will be set to run `cargo tarpaulin --profile release` in
  the workspace.
  - `CARGO_PROFILE` can be set on the derivation to alter which cargo profile is
    selected; setting it to `""` will omit specifying a profile altogether.
* `pnameSuffix` will be set to `"-tarpaulin"`

#### Required attributes
* `cargoArtifacts`: A path (or derivation) which contains an existing cargo
  `target` directory, which will be reused at the start of the derivation.
  Useful for caching incremental cargo builds.
  - This can be prepared via `buildDepsOnly`
  - Alternatively, any cargo-based derivation which was built with
    `doInstallCargoArtifacts = true` will work as well

#### Optional attributes
* `cargoExtraArgs`: additional flags to be passed in the cargo invocation
  - Default value: `""`
* `cargoTarpaulinExtraArgs`: additional flags to be passed in the cargo
  tarpaulin invocation
  - Default value: `"--skip-clean --out xml --output-dir $out"`
* `doNotLinkInheritedArtifacts` will be set to `true` if not specified.

#### Native build dependencies
The `cargo-tarpaulin` package is automatically appended as a native build input to any
other `nativeBuildInputs` specified by the caller.

#### Remove attributes
The following attributes will be removed before being lowered to
`mkCargoDerivation`. If you absolutely need these attributes present as
environment variables during the build, you can bring them back via
`.overrideAttrs`.
* `cargoExtraArgs`
* `cargoTarpaulinExtraArgs`

### `craneLib.cargoTest`

`cargoTest :: set -> drv`

Create a derivation which will run a `cargo test` invocation in a cargo
workspace.

Except where noted below, all derivation attributes are delegated to
* `buildPhaseCargoCommand` will be set to run `cargo test --profile release` in
  the workspace.
  - `CARGO_PROFILE` can be set on the derivation to alter which cargo profile is
    selected; setting it to `""` will omit specifying a profile altogether.
* `pnameSuffix` will be set to `"-test"`

#### Optional attributes
* `cargoExtraArgs`: additional flags to be passed in the cargo invocation
  - Default value: `"--locked"`
* `cargoTestArgs`: additional flags to be passed in the cargo
  invocation
  - Default value: `""`

#### Remove attributes
The following attributes will be removed before being lowered to
`mkCargoDerivation`. If you absolutely need these attributes present as
environment variables during the build, you can bring them back via
`.overrideAttrs`.
* `cargoExtraArgs`
* `cargoTestExtraArgs`

### `craneLib.cleanCargoSource`

`cleanCargoSource :: path or drv -> drv`

Cleans a source tree to omit things like version control directories as well
omit any non-Rust/non-cargo related files. Useful to avoid rebuilding a project
when unrelated files are changed (e.g. `flake.nix` or any other nix files).

The final output will be cleaned by both `cleanSource` (from nixpkgs) and
`craneLib.filterCargoSources`. See each of them for more details on which files are
kept.

If it is necessary to customize which files are kept, a custom filter can be
written (which may want to also call `craneLib.filterCargoSources`) to achieve the
desired behavior.

```nix
craneLib.cleanCargoSource (craneLib.path ./.)
```

### `craneLib.cleanCargoToml`

`cleanCargoToml :: set -> set`

Cleans all definitions from a Cargo.toml file which are irrelevant for a
minimal build of a package's dependencies. See `mkDummySrc` for more information
on how the result is applied.

In general, the following types of attributes are kept from the original input:
* basic package definitions (like name and version)
* dependency definitions
* feature definitions
* workspace definitions
* anything pertaining to project structure (like bin/lib targets, tests, etc.)

```nix
craneLib.cleanCargoToml { cargoToml = ./Cargo.toml; }
# { dependencies = { byteorder = "*"; }; package = { edition = "2021"; name = "simple"; version = "0.1.0"; }; }
```

#### Input attributes
* `cargoToml`: a path to a Cargo.toml file
* `cargoTomlContents`: the contents of a Cargo.toml file as a string

At least one of the above attributes must be specified, or an error will be
raised during evaluation.

### `craneLib.crateNameFromCargoToml`

`crateNameFromCargoToml :: set -> set`

Extract a crate's name and version from its Cargo.toml file.

The resulting `pname` attribute will be populated with the value of the
Cargo.toml's (top-level) attributes in the following order, where the first
attribute (with a string value) will be chosen:
1. `package.metadata.crane.name`
1. `package.name`
1. `workspace.metadata.crane.name`
1. (Deprecated) `workspace.package.name`
1. Otherwise a placeholder name will be used

The resulting `version` attribute will be populated with the value of the
Cargo.toml's (top-level) attributes in the following order, where the first
attribute (with a string value) will be chosen:
1. `package.version`
1. `workspace.package.version`
1. Otherwise a placeholder version will be used

Note that *only the root `Cargo.toml` of the specified source will be checked*.
Directories **will not be crawled** to resolve potential workspace inheritance.

```nix
craneLib.crateNameFromCargoToml { cargoToml = ./Cargo.toml; }
# { pname = "simple"; version = "0.1.0"; }
```

### `craneLib.crateRegistries`

`crateRegistries :: set`

A set of crate registries made available for use in downloading crate sources.
The keys are registry URLs as used in the Cargo.lock file (e.g.
"registry+https://...") and the values are the download URL for that registry,
including any [placeholder
values](https://doc.rust-lang.org/cargo/reference/registries.html#index-format)
cargo is expected to populate for downloads.

This definition can be updated via `appendCrateRegistries`.

#### Input attributes
* `src`: a directory which includes a Cargo.toml file at its root.
* `cargoToml`: a path to a Cargo.toml file
* `cargoTomlContents`: the contents of a Cargo.toml file as a string

At least one of the above attributes must be specified, or an error will be
raised during evaluation.

#### Output attributes
* `pname`: the name of the crate
  - Default value: `"cargo-package"` if the specified Cargo.toml file did not
    include a name
* `version`: the version of the crate
  - Default value: `"0.0.1"` if the specified Cargo.toml file did not
    include a version

### `craneLib.devShell`

`devShell :: set -> drv`

A thin wrapper around
[`pkgs.mkShell`](https://nixos.org/manual/nixpkgs/stable/#sec-pkgs-mkShell) for
creating development shells for use with `nix develop` (see [“Local
Development”](local_development.md)). Except where noted below, all derivation
attributes are passed straight through, so any `mkShell` behavior can be used
as expected: namely, all key-value pairs other than those `mkShell` consumes
will be set as environment variables in the resulting shell.

Note that the current toolchain's `cargo`, `clippy`, `rustc`, and `rustfmt`
packages will automatically be added to the devShell.

#### Optional attributes
* `checks`: A set of checks to inherit inputs from, typically
  `self.checks.${system}`. Build inputs from the values in this attribute set
  are added to the created shell environment for interactive use.
* `inputsFrom`: A list of extra packages to inherit inputs from. Note that
  these packages are _not_ added to the result environment; use
  `packages` for that.
* `packages`: A list of extra packages to add to the created shell environment.
* `shellHook`: A string of bash statements that will be executed when the shell
  is entered with `nix develop`.

See the [quick start example](examples/quick-start.md) for usage in a
`flake.nix` file.

```nix
craneLib.devShell {
  checks = self.checks.${system};

  packages = [
    pkgs.ripgrep
  ];

  # Set a `cargo-nextest` profile:
  NEXTEST_PROFILE = "local";
}
```

```nix
craneLib.devShell {
  checks = {
    my-package-clippy = craneLib.cargoClippy commonArgs;
    my-package-doc = craneLib.cargoDoc commonArgs;
    my-package-nextest = craneLib.cargoNextest commonArgs;
  };
}
```

### `craneLib.downloadCargoPackage`

`downloadCargoPackage :: set -> drv`

Download a packaged cargo crate (e.g. from crates.io) and prepare it for
vendoring.

The registry's `fetchurlExtraArgs` will be passed through to `fetchurl` when
downloading the crate, making it possible to influence interacting with the
registry's API if necessary.

#### Required input attributes
* `checksum`: the (sha256) checksum recorded in the Cargo.lock file
* `name`: the name of the crate
* `source`: the source key recorded in the Cargo.lock file
* `version`: the version of the crate

#### Attributes of the vendor-prep derivation
* `dontBuild`: `true`
* `dontConfigure`: `true`
* `dontFixup`: `true`
* `pname`: `"cargo-package-"` suffixed by the package name in `Cargo.lock`
* `sourceRoot`: `"./crate"`
* `version`: inherited from the package version in `Cargo.lock`
* `unpackPhase`: This phase will:
   1. run the `preUnpack` hook
   1. create an empty directory named `./crate`
   1. unpack the crate's tarball under `./crate`
   1. run the `postUnpack` hook
* `installPhase`: This phase will:
   1. run the `preInstall` hook
   1. move the contents of the current directory (i.e. `./crate` by default) to
      `$out`
   1. populate `$out/.cargo-checksum.json`
   1. run the `postInstall` hook

### `craneLib.downloadCargoPackageFromGit`

`downloadCargoPackageFromGit :: set -> drv`

Download a git repository containing a cargo crate or workspace, and prepare it
any crates it contains for vendoring.

#### Required input attributes
* `git`: the URL to the repository
* `rev`: the exact revision to check out

#### Optional attributes
* `allRefs`: whether all git refs should be fetched in order to look for the
  specified `rev`
  - Default value: `true` if `ref` is set to `null`, `false` otherwise
* `ref`: the ref (i.e. branch or tag) to which `rev` belongs to. For branches it
  should be `"refs/head/${branch}"` and for tags it should be
  `"refs/tags/${tag}"`
  - Default value: `null`
* `sha256`: the sha256 hash of the (unpacked) download. If provided `fetchgit` will be used
  (instead of `builtins.fetchGit`) which allows for offline evaluations.
  - Default value: `null`

#### Attributes of the vendor-prep derivation
* `dontBuild`: `true`
* `dontConfigure`: `true`
* `dontFixup`: `true`
* `installPhase`: This phase will:
   1. run the `preInstall` hook
   1. Prepare the current directory for vendoring by:
      - Searching for all `Cargo.toml` files
      - Copying their parent directory to `$out/$crate` (where `$crate` is the
        package name and version as defined in `Cargo.toml`)
      - Populating `.cargo-checksum.json`
      - Running `crane-resolve-workspace-inheritance` on the `Cargo.toml`
      - Note that duplicate crates (whose name and version collide) are ignored
   1. run the `postInstall` hook
* `nativeBuildInputs`: A list of the `cargo`, `craneUtils`, and `jq` packages
* `name`: set to `"cargo-git"`
* `src`: the git repo checkout, as determined by the input parameters

### `craneLib.findCargoFiles`

`findCargoFiles :: path -> set of lists`

Given a path, recursively search it for any `Cargo.toml`, `.cargo/config` or
`.cargo/config.toml` files.

```nix
craneLib.findCargoFiles ./src
# { cargoTomls = [ "..." ]; cargoConfigs = [ "..." ]; }
```

### `craneLib.filterCargoSources`

`filterCargoSources :: path -> string -> bool`

A source filter which when used with `cleanSourceWith` (from nixpkgs's `lib`)
will retain the following files from a given source:
- Cargo files (`Cargo.toml`, `Cargo.lock`, `.cargo/config.toml`, `.cargo/config`)
- Rust files (files whose name end with `.rs`)
- TOML files (files whose name end with `.toml`)

```nix
cleanSourceWith {
  src = craneLib.path ./.;
  filter = craneLib.filterCargoSources;
}
```

Note that it is possible to compose source filters, especially if
`filterCargoSources` omits files which are relevant to the build. For example:

```nix
let
  # Only keeps markdown files
  markdownFilter = path: _type: builtins.match ".*md$" path != null;
  markdownOrCargo = path: type:
    (markdownFilter path type) || (craneLib.filterCargoSources path type);
in
cleanSourceWith {
  src = craneLib.path ./.;
  filter = markdownOrCargo;
}
```

### `craneLib.mkCargoDerivation`

`mkCargoDerivation :: set -> drv`

A thin wrapper around `stdenv.mkDerivation` which includes common hooks for
building a derivation using cargo. Except where noted below, all derivation
attributes are passed straight through, so any common derivation behavior can be
used as expected: namely all key-value pairs will be set as environment
variables for the derivation's build script.

This is a fairly low-level abstraction, so consider using `buildPackage` or
`cargoBuild` if they fit your needs.

#### Required attributes
* `buildPhaseCargoCommand`: A command (likely a cargo invocation) to run during
  the derivation's build phase. Pre and post build hooks will automatically be
  run.
* `cargoArtifacts`: A path (or derivation) which contains an existing cargo
  `target` directory, which will be reused at the start of the derivation.
  Useful for caching incremental cargo builds.
  - This can be prepared via `buildDepsOnly`
  - Alternatively, any cargo-based derivation which was built with
    `doInstallCargoArtifacts = true` will work as well

#### Optional attributes
* `buildPhase`: the commands used by the build phase of the derivation
  - Default value: the build phase will run `preBuild` hooks, print the cargo
    version, log and evaluate `buildPhaseCargoCommand`, and run `postBuild`
    hooks
* `cargoLock`: if set will be passed through to the derivation and the path it
  points to will be copied as the workspace `Cargo.lock`
  - Unset by default
* `cargoLockContents`: if set and `cargoLock` is missing or null, its value will
  be written as the workspace `Cargo.lock`
  - Unset by default
* `cargoLockParsed`: if set and both `cargoLock` and `cargoLockContents` are
  missing or null, its value will be serialized as TOML and the result written
  as the workspace `Cargo.lock`
  - Unset by default
* `cargoVendorDir`: A path (or derivation) of vendored cargo sources which can
  be consumed without network access. Directory structure should basically
  follow the output of `cargo vendor`.
  - Default value: the result of `vendorCargoDeps` after applying the arguments
    set (with the respective default values)
* `checkPhase`: the commands used by the check phase of the derivation
  - Default value: the check phase will run `preCheck` hooks, log and evaluate
    `checkPhaseCargoCommand`, and run `postCheck` hooks
* `checkPhaseCargoCommand`: A command (likely a cargo invocation) to run during
  the derivation's check phase. Pre and post check hooks will automatically be
  run.
  - Default value: `""`
* `configurePhase`: the commands used by the configure phase of the derivation
  - Default value: the configure phase will run `preConfigureHooks` hooks, then
    run `postConfigure` hooks
* `doInstallCargoArtifacts`: controls whether cargo's `target` directory should
  be copied as an output
  - Default value: `true`
* `installPhase`: the commands used by the install phase of the derivation
  - Default value: the install phase will run `preInstall` hooks, log and evaluate
    `installPhaseCommand`, and run `postInstall` hooks
* `installPhaseCommand`: the command(s) which are expected to install the
  derivation's outputs.
  - Default value: `"mkdir -p $out"`
  - By default an output directory is created such that any other `postInstall`
    hooks can successfully run. Consider overriding this value with an
    appropriate installation commands for the package being built.
* `pname`: the name of the derivation
  - Default value: the package name listed in `Cargo.toml`
* `pnameSuffix`: a suffix appended to `pname`
  - Default value: `""`
* `stdenv`: the standard build environment to use for this derivation
  - Default value: `pkgs.stdenv`
* `version`: the version of the derivation
  - Default value: the version listed in `Cargo.toml`

#### Remove attributes
The following attributes will be removed before being lowered to
`stdenv.mkDerivation`. If you absolutely need these attributes present as
environment variables during the build, you can bring them back via
`.overrideAttrs`.

* `buildPhaseCargoCommand`
* `cargoLock`
* `cargoLockContents`
* `cargoLockParsed`
* `checkPhaseCargoCommand`
* `installPhaseCommand`
* `outputHashes`
* `pnameSuffix`
* `stdenv`

#### Native build dependencies and included hooks
The `cargo` package is automatically appended as a native build input to any
other `nativeBuildInputs` specified by the caller, along with the following
hooks:
* `cargoHelperFunctionsHook`
* `configureCargoCommonVarsHook`
* `configureCargoVendoredDepsHook`
* `inheritCargoArtifactsHook`
* `installCargoArtifactsHook`
* `replaceCargoLockHook`
* `rsync`
* `zstd`

### `craneLib.mkDummySrc`

`mkDummySrc :: set -> drv`

Converts a given source directory of a cargo workspace to the smallest, most
trivial form needed to build all dependencies such that their artifacts can be
cached.

The actual source files of the project itself are ignored/replaced with
empty programs, such that changes to the source files does not invalidate any
build caches. More specifically:
* The Cargo.lock file is kept as-is
  - Any changes to it will invalidate the build cache
* Any cargo configuration files (i.e. files name `config` or `config.toml` whose
  parent directory is named `.cargo`) are kept as-is.
  - Any changes to these files will invalidate the build cache
* Any files named `Cargo.toml` are reduced via `cleanCargoToml` and the result
  is kept. Only the following changes will result in invalidating the build
  cache:
  - Any changes to listed dependencies
  - Any changes to feature definitions
  - Any changes to the workspace member metadata
  - Any changes to the `[package]` definition such as name and version
  - Any changes to the name or path of any target (such as benches, bins,
    examples, libs, or tests)

#### Required attributes
* `src`: a source directory which should be turned into a "dummy" form

#### Optional attributes
* `cargoLock`: a path to a Cargo.lock file
  - Default value: `src + /Cargo.lock`
* `dummyrs`: a path to a file which will be used in place of all dummy rust
  files (e.g. `main.rs`, `lib.rs`, etc.). This can be useful to customize dummy
  source files (e.g. enable certain lang features for a given target).
  - Default value: an empty `fn main` declaration and conditionally enabled
    `#![no_std]` if the `target_os` cfg is set to `"none"` or `"uefi"`.
* `extraDummyScript`: additional shell script which will be run inside the builder
  verbatim. Useful for customizing what the dummy sources include by running any
  arbitrary commands.
  - Default value: `""`
  - Note that this script will run in an environment
    _where the original source is not present_ as doing so would cause a rebuild
    if any part of the source changed. Additional files can be copied to the
    derivation's result, but care must be taken that the derivation only depends
    on (i.e. is rebuilt if) the smallest subset of the original source as
    required.
  - Here is an example of how to include an entire directory, in this case
    `.cargo`, but any other directory would work as well:
    ```nix
    let
      # The _entire_ source of the project. mkDummySrc will automatically
      # filter out irrelevant files as described above
      src = craneLib.path ./.;

      dotCargoOnly = lib.cleanSourceWith {
        inherit src;
        # Only keep `*/.cargo/*`
        filter = path: _type: lib.hasInfix ".cargo" path;
      };
    in
    mkDummySrc {
      inherit src;

      # Note that here we scope the path to only contain any `.cargo` directory
      # and its contents and not any other  directories which may exist at the
      # root of the project. Also note that the entire path is inside of the
      # `${ }` which ensures that the derivation only consumes that directory.
      # Writing `${./.}/.cargo` would incorrectly consume the entire source root,
      # and therefore rebuild everything when any file changes, which defeats
      # artifact caching.
      #
      # Also note the `--no-target-directory` flag which ensures the results are
      # copied to `$out/.cargo` instead of something like `$out/HASH-.cargo`
      extraDummyScript = ''
        cp -r ${dotCargoOnly} --no-target-directory $out/
      '';
    }
    ```


### `craneLib.overrideToolchain`

`overrideToolchain :: drv -> set`

A convenience method to override and use tools (like `cargo`, `clippy`,
`rustfmt`, `rustc`, etc.) from one specific toolchain. The input should be a
single derivation which contains all the tools as binaries. For example, this
can be the output of `oxalica/rust-overlay`.

```nix
craneLib.overrideToolchain myCustomToolchain
```

### `craneLib.path`

`path :: path -> drv`

`path :: set -> drv`

A convenience wrapper around `builtins.path` which will automatically set the
path's `name` to the workspace's package name (or a placeholder value of
`"source"` if a name cannot be determined).

It should be used anywhere a relative path like `./.` or `./..` is needed so
that the result is reproducible and caches can be reused. Otherwise the store
path [will depend on the name of the parent
directory](https://nix.dev/anti-patterns/language#reproducibility-referencing-top-level-directory-with) which may cause unnecessary rebuilds.

```nix
craneLib.path ./.
# "/nix/store/wbhf6c7wiw9z53hsn487a8wswivwdw81-source"
```

```nix
craneLib.path ./checks/simple
# "/nix/store/s9scn97c86kqskf7yv5n2k85in5y5cmy-simple"
```

It is also possible to use as a drop in replacement for `builtins.path`:
```nix
craneLib.path {
  path = ./.;
  name = "asdf";
}
# "/nix/store/23zy3c68v789cg8sysgba0rbgbfcjfhn-asdf"
```

### `craneLib.registryFromDownloadUrl`

`registryFromDownloadUrl :: set -> set`

Prepares a crate registry into a format that can be passed directly to
`appendCrateRegistries` using the registry's download URL.

If the registry in question has a stable download URL (which either never
changes, or it does so very infrequently), then `registryFromDownloadUrl` is a
great and lightweight choice for including the registry. To get started, look up
the
[`config.json`](https://github.com/rust-lang/crates.io-index/blob/24ecfa9c82456a79ec115736f1fcefc0be375b52/config.json#L2) at the registry's root and copy the value of the `dl` entry.

If the registry's download endpoint changes more frequently and you would like
to infer the configuration directly from a git revision, consider using
`registryFromGitIndex` as an alternative.

If the registry needs a special way of accessing crate sources the
`fetchurlExtraArgs` set can be used to influence the behavior of fetching the
crate sources (e.g. by setting `curlOptsList`)

#### Required attributes
* `dl`: the value of the `dl` entry in the registry's `config.json` file
* `indexUrl`: an HTTP URL to the index

#### Optional attributes
* `fetchurlExtraArgs`: a set of arguments which will be passed on to the
  `fetchurl` for each crate being sourced from this registry

```nix
craneLib.registryFromDownloadUrl {
  dl = "https://static.crates.io/crates";
  indexUrl = "https://github.com/rust-lang/crates.io-index";
}
# {
#   "registry+https://github.com/rust-lang/crates.io-index" = {
#     downloadUrl = "https://static.crates.io/crates/{crate}/{version}/download";
#     fetchurlExtraArgs = {};
#   };
# }
```

### `craneLib.registryFromGitIndex`

`registryFromGitIndex :: set -> set`

Prepares a crate registry into a format that can be passed directly to
`appendCrateRegistries` using a revision of the registry index to infer the
download URL.

Note that the specified git revision _does not need to track updates to the
index itself_ as long as the pinned revision contains the most recent version of
the `config.json` file. In other words, this commit revision only needs to be
updated if the `config.json` file changes.

Also note that this approach means that the contents of the entire index at the
specified revision will be added to the Nix store during evaluation time, and
that IFD will need to be enabled. If this is unsatisfactory, consider using
`registryFromDownloadUrl` as a simpler alternative.

If the registry needs a special way of accessing crate sources the
`fetchurlExtraArgs` set can be used to influence the behavior of fetching the
crate sources (e.g. by setting `curlOptsList`)

#### Required attributes
* `indexUrl`: an HTTP URL to the index
* `rev`: any git revision which contains the latest `config.json` definition

#### Optional attributes
* `fetchurlExtraArgs`: a set of arguments which will be passed on to the
  `fetchurl` for each crate being sourced from this registry

```nix
craneLib.registryFromGitIndex {
  url = "https://github.com/Hirevo/alexandrie-index";
  rev = "90df25daf291d402d1ded8c32c23d5e1498c6725";
}
# {
#   "registry+https://github.com/Hirevo/alexandrie-index" = {
#     downloadUrl = "https://crates.polomack.eu/api/v1/crates/{crate}/{version}/download";
#     fetchurlExtraArgs = {};
#   };
# }
```

### `craneLib.urlForCargoPackage`

`urlForCargoPackage :: set -> set`

Returns info pertaining to the URL for downloading a particular crate if the
crate's registry is configured (an error will be thrown if it is not).

The result will contain two attributes:
- `url`: A string representing the URL at which the crate can be fetched
- `fetchurlExtraArgs`: A set of attributes specific to this registry which will
  be passed on to the `fetchurl` invocation.

#### Required input attributes
* `name`: the name of the crate
* `source`: the source key recorded in the Cargo.lock file
* `version`: the version of the crate

### `craneLib.vendorCargoDeps`

`vendorCargoDeps :: set -> drv`

Creates a derivation which will download all crates referenced by a Cargo.lock
file, and prepare a vendored directory which cargo can use for subsequent builds
without needing network access.

Each unique crate index will be vendored as its own subdirectory within the
output of the derivation. A `config.toml` file will also be placed at the root
of the output which will contain the necessary configurations to point cargo to
the vendored directories (i.e. this configuration can be appended to the
`.cargo/config.toml` definition of the project).

#### Input attributes
* `src`: a directory which includes a Cargo.lock file at its root.
* `cargoLock`: a path to a Cargo.lock file
* `cargoLockContents`: the contents of a Cargo.lock file as a string
* `cargoLockParsed`: the parsed contents of Cargo.lock as an attribute set

At least one of the above attributes must be specified, or an error will be
raised during evaluation.

#### Optional attributes
* `outputHashes`: a mapping of package-source to the sha256 of the (unpacked)
  download. Useful for supporting fully offline evaluations.
  - Default value: `[]`
* `overrideVendorCargoPackage`: a function that will be called on every crate
  vendored from a cargo registry, which allows for modifying the derivation
  which will unpack the cargo tarball (e.g. to patch the crate source).
  It will be called with the following parameters:
  1. The `Cargo.lock` entry for that package (to allow conditional overrides
     based on the package name/version/source, etc.)
  1. The default `downloadCargoPackage` derivation
  - Default value: `_p: drv: drv`
* `overrideVendorGitCheckout`: a function that will be called on every unique
  checkout vendored from a git repository, which allows for modifying the
  derivation which will unpack the cargo crates found in the checkout (e.g. to
  patch the crate sources). It will be called with the following
  parameters:
  1. A list of the `Cargo.lock` entries for each package which shares the same
     repo URL and revision to checkout (to allow conditional overrides based on
     the repo/checkout etc.)
  1. The default `downloadCargoPackageFromGit` derivation
  - Default value: `_ps: drv: drv`

### `craneLib.vendorCargoRegistries`

`vendorCargoRegistries :: set -> set`

Creates the derivations necessary to download all crates from all registries
referenced by a `Cargo.lock` file, and prepare the vendored directories which
cargo can use for subsequent builds without needing network access.

#### Input attributes
* `lockPackages`: a list of all `[[package]]` entries found in the project's
  `Cargo.lock` file (parsed via `builtins.fromTOML`)

#### Optional attributes
* `cargoConfigs`: a list of paths to all `.cargo/config.toml` files which may
  appear in the project. Ignored if `registries` is set.
  - Default value: `[]`
* `overrideVendorCargoPackage`: a function that will be called on every crate
  vendored from a cargo registry, which allows for modifying the derivation
  which will unpack the cargo tarball (e.g. to patch the crate source).
  It will be called with the following parameters:
  1. The `Cargo.lock` entry for that package (to allow conditional overrides
     based on the package name/version/source, etc.)
  1. The default `downloadCargoPackage` derivation
  - Default value: `_p: drv: drv`
* `registries`: an attrset of registry names to their index URL. The default
  ("crates-io") registry need not be specified, as it will automatically be
  available, but it can be overridden if required.
  - Default value: if not specified, `cargoConfigs` will be used to identify any
    configured registries

#### Output attributes
* `config`: the configuration entires needed to point cargo to the vendored
  crates. This is intended to be appended to `$CARGO_HOME/config.toml` verbatim
* `sources`: an attribute set of all the newly created cargo sources' names to
  their location in the Nix store

### `craneLib.vendorGitDeps`

`vendorGitDeps :: set -> set`

Creates the derivations necessary to download all crates from all git
dependencies referenced by a `Cargo.lock` file, and prepare the vendored
directories which cargo can use for subsequent builds without needing network
access.

#### Input attributes
* `lockPackages`: a list of all `[[package]]` entries found in the project's
  `Cargo.lock` file (parsed via `builtins.fromTOML`)

#### Optional attributes
* `outputHashes`: a mapping of package-source to the sha256 of the (unpacked)
  download. Useful for supporting fully offline evaluations.
  - Default value: `[]`
* `overrideVendorGitCheckout`: a function that will be called on every unique
  checkout vendored from a git repository, which allows for modifying the
  derivation which will unpack the cargo crates found in the checkout (e.g. to
  patch the crate sources). It will be called with the following
  parameters:
  1. A list of the `Cargo.lock` entries for each package which shares the same
     repo URL and revision to checkout (to allow conditional overrides based on
     the repo/checkout etc.)
  1. The default `downloadCargoPackageFromGit` derivation
  - Default value: `_ps: drv: drv`

#### Output attributes
* `config`: the configuration entires needed to point cargo to the vendored
  sources. This is intended to be appended to `$CARGO_HOME/config.toml` verbatim
* `sources`: an attribute set of all the newly created cargo sources' names to
  their location in the Nix store

### `craneLib.vendorMultipleCargoDeps`

`vendorMultipleCargoDeps :: set -> drv`

Creates a derivation which will download all crates referenced by several
`Cargo.lock` files, and prepare a vendored directory which cargo can use for
subsequent builds without needing network access. Duplicate packages listed in
different `Cargo.lock` files will automatically be filtered out.

Each unique crate index will be vendored as its own subdirectory within the
output of the derivation. A `config.toml` file will also be placed at the root
of the output which will contain the necessary configurations to point cargo to
the vendored directories (i.e. this configuration can be appended to the
`.cargo/config.toml` definition of the project).

#### Optional attributes
* `cargoConfigs`: a list of paths to all `.cargo/config.toml` files which may
  appear in the project. Ignored if `registries` is set.
  - Default value: `[]`
* `cargoLockContentsList`: a list of strings representing the contents of
  different `Cargo.lock` files to be included while vendoring. The strings will
  automatically be parsed during evaluation.
  - Default value: `[]`
* `cargoLockList`: a list of paths to different `Cargo.lock` files to be
  included while vendoring. The paths will automatically be read and parsed
  during evaluation.
  - Default value: `[]`
* `cargoLockParsedList`: a list of attrsets representing the parsed contents of
  different `Cargo.lock` files to be included while vendoring.
  - Default value: `[]`
* `outputHashes`: a mapping of package-source to the sha256 of the (unpacked)
  download. Useful for supporting fully offline evaluations.
  - Default value: `[]`
* `overrideVendorCargoPackage`: a function that will be called on every crate
  vendored from a cargo registry, which allows for modifying the derivation
  which will unpack the cargo tarball (e.g. to patch the crate source).
  It will be called with the following parameters:
  1. The `Cargo.lock` entry for that package (to allow conditional overrides
     based on the package name/version/source, etc.)
  1. The default `downloadCargoPackage` derivation
  - Default value: `_p: drv: drv`
* `overrideVendorGitCheckout`: a function that will be called on every unique
  checkout vendored from a git repository, which allows for modifying the
  derivation which will unpack the cargo crates found in the checkout (e.g. to
  patch the crate sources). It will be called with the following
  parameters:
  1. A list of the `Cargo.lock` entries for each package which shares the same
     repo URL and revision to checkout (to allow conditional overrides based on
     the repo/checkout etc.)
  1. The default `downloadCargoPackageFromGit` derivation
  - Default value: `_ps: drv: drv`
* `registries`: an attrset of registry names to their index URL. The default
  ("crates-io") registry need not be specified, as it will automatically be
  available, but it can be overridden if required.
  - Default value: if not specified, `cargoConfigs` will be used to identify any
    configured registries

### `craneLib.writeTOML`

`writeTOML :: String -> String -> drv`

Takes a file name and an attribute set, converts the set to a TOML document and
writes it to a file with the given name.

```nix
craneLib.writeTOML "foo.toml" { foo.bar = "baz"; }
# «derivation /nix/store/...-foo.toml.drv»
```

## Hooks

### `craneLib.cargoHelperFunctionsHook`

Defines helper functions for internal use. It is probably not a great idea to
depend on these directly as their behavior can change at any time, but it is
worth documenting them just in case:

* Defines a `cargo()` function which will immediately invoke the `cargo` command
  found on the `$PATH` after echoing the exact arguments that were passed in.
  Useful for automatically logging all cargo invocations to the log.
* Defines a `cargoWithProfile()` function which will invoke `cargo` with the
  provided arguments. If `$CARGO_PROFILE` is set, then `--profile
  $CARGO_PROFILE` will be injected into the `cargo` invocation
  - Note: a default value of `$CARGO_PROFILE` is set via
    `configureCargoCommonVarsHook`. You can set `CARGO_PROFILE = "something"` in
    your derivation to change which profile is used, or set `CARGO_PROFILE =
    "";` to omit it altogether.

### `craneLib.configureCargoCommonVarsHook`

Defines `configureCargoCommonVars()` which will set various common cargo-related
variables, such as honoring the amount of parallelism dictated by Nix, disabling
incremental artifacts, etc. More specifically:
* `CARGO_BUILD_INCREMENTAL` is set to `false` if not already defined
* `CARGO_BUILD_JOBS` is set to `$NIX_BUILD_CORES` if not already defined
* `CARGO_HOME` is set to `$PWD/.cargo-home` if not already defined.
  - The directory that `CARGO_HOME` points to will be created
* `CARGO_PROFILE` is set to `release` if not already defined.
  - Note that this is is used internally specify a cargo profile (e.g. `cargo
    build --profile release`) and not something natively understood by cargo.
* `RUST_TEST_THREADS` is set to `$NIX_BUILD_CORES` if not already defined

**Automatic behavior:** runs as a post-patch hook

### `craneLib.configureCargoVendoredDepsHook`

Defines `configureCargoVendoredDeps()` which will prepare cargo to use a
directory of vendored crate sources. It takes two positional arguments:
1. a path to the vendored sources
   * If not specified, the value of `$cargoVendorDir` will be used
   * If `cargoVendorDir` is not specified, an error will be raised
1. a path to a cargo config file to modify
   * If not specified, the value of `$CARGO_HOME/config.toml` will be used
   * This cargo config file will be appended with a stanza which will instruct
     cargo to use the vendored sources (instead of downloading the sources
     directly) as follows:
       - If the vendored directory path contains a file named `config.toml`,
         then its contents will be appended to the specified cargo config path.
       - Otherwise the entire vendored directory path will be treated as if it
         only vendors the crates.io index and will be configured as such.

**Automatic behavior:** if `cargoVendorDir` is set, then
`configureCargoVendoredDeps "$cargoVendorDir" "$CARGO_HOME/config.toml"` will be
run as a pre configure hook.

### `craneLib.inheritCargoArtifactsHook`

Defines `inheritCargoArtifacts()` which will pre-populate cargo's artifact
directory using a previous derivation. It takes two positional arguments:
1. a path to the previously prepared artifacts
   * If not specified, the value of `$cargoArtifacts` will be used
   * If `cargoArtifacts` is not specified, an error will be raised
   * If the specified path is a directory which contains a file called
     `target.tar.zst`, then that file will be used as specified below
   * If the specified path is a file (and not a directory) it is assumed that it
     contains a zstd compressed tarball and will be decompressed and unpacked
     into the specified cargo artifacts directory
   * If the specified path is a directory which contains another directory
     called `target`, then that directory will be used as specified below
   * If the specified path is a directory, its contents will be copied into the
     specified cargo artifacts directory
   * The previously prepared artifacts are expected to be a zstd compressed
     tarball
1. the path to cargo's artifact directory, where the previously prepared
   artifacts should be unpacked
   * If not specified, the value of `$CARGO_TARGET_DIR` will be used
   * If `CARGO_TARGET_DIR` is not set, cargo's default target location  (i.e.
     `./target`) will be used.

Note that as an optimization, some dependency artifacts will be symlinked
instead of (deeply) copied to `$CARGO_TARGET_DIR`. To disable this behavior set
`doNotLinkInheritedArtifacts`, and all artifacts will be copied as plain,
writable files.

**Automatic behavior:** if `cargoArtifacts` is set, then
`inheritCargoArtifacts "$cargoArtifacts" "$CARGO_TARGET_DIR"` will be run as a
post patch hook.

**Required nativeBuildInputs**: assumes `zstd` is available on the `$PATH`

### `craneLib.installCargoArtifactsHook`

Defines `compressAndInstallCargoArtifactsDir()` which handles installing
cargo's artifact directory to the derivation's output as a zstd compressed
tarball. It takes two positional arguments:
1. the installation directory for the output.
   * An error will be raised if not specified
   * Cargo's artifact directory will be compressed as a reproducible tarball
     with zstd compression. It will be written to this directory and named
     `target.tar.zstd`
1. the path to cargo's artifact directory
   * An error will be raised if not specified

If `$zstdCompressionExtraArgs` is set, `compressAndInstallCargoArtifactsDir()`
will pass its contents along to `zstd` when compressing artifacts.

Defines `dedupAndInstallCargoArtifactsDir()` which handles installing
cargo's artifact directory to the derivation's output after deduplicating
identical files against a directory of previously prepared cargo artifacts.
It takes three positional arguments:
1. the installation directory for the output.
   * An error will be raised if not specified
   * If the specified path is a directory which exists then the current cargo
     artifacts will be compared with the contents of said directory. Any files
     whose contents and paths match will be symbolically linked together to
     reduce the size of the data stored in the Nix store.
1. the path to cargo's artifact directory
   * An error will be raised if not specified
1. a path to the previously prepared cargo artifacts
   * An error will be raised if not specified
   * `/dev/null` can be specified here if there is no previous directory to
     deduplicate against

Defines `prepareAndInstallCargoArtifactsDir()` which handles installing cargo's
artifact directory to the derivation's output. It takes three positional
arguments:
1. the installation directory for the output.
   * If not specified, the value of `$out` will be used
   * Cargo's artifact directory will be installed based on the installation mode
     selected below
1. the path to cargo's artifact directory
   * If not specified, the value of `$CARGO_TARGET_DIR` will be used
   * If `CARGO_TARGET_DIR` is not set, cargo's default target location  (i.e.
     `./target`) will be used.
1. the installation mode to apply
   * If specified, the value of `$installCargoArtifactsMode` will be used,
     otherwise, a default value of `"use-zstd"` will be used
   * If set to "use-symlink" then `dedupAndInstallCargoArtifactsDir()` will be
     used.
     - If `$cargoArtifacts` is defined and `$cargoArtifacts/target` is a valid
       directory, it will be used during file deduplication
   * If set to "use-zstd" then `compressAndInstallCargoArtifactsDir()` will be
     used.
   * Otherwise an error will be raised if the mode is not recognized

**Automatic behavior:** if `doInstallCargoArtifacts` is set to `1`, then
`prepareAndInstallCargoArtifactsDir "$out" "$CARGO_TARGET_DIR"` will be run as a
post install hook.

**Required nativeBuildInputs**: assumes `zstd` is available on the `$PATH`

### `craneLib.installFromCargoBuildLogHook`

Defines `installFromCargoBuildLog()` which will use a build log produced by
cargo to find and install any binaries and libraries which have been built. It
takes two positional arguments:
1. a path to where artifacts should be installed
   * If not specified, the value of `$out` will be used
   * Binaries will be installed in a `bin` subdirectory
   * Libraries will be installed in a `lib` subdirectory
     - Note that only library targets with the `staticlib` and `cdylib`
       crate-types will be installed. Library targets with the `rlib` crate-type
       will be ignored
1. a path to a JSON formatted build log written by cargo
   * If not specified, the value of `$cargoBuildLog` will be used
   * If `cargoBuildLog` is not set, an error will be raised
   * This log can be captured, for example, via `cargo build --message-format
     json-render-diagnostics >cargo-build.json`

**Automatic behavior:** none

**Required nativeBuildInputs**: assumes `cargo` and `jq` are available on the `$PATH`

### `craneLib.removeReferencesToVendoredSourcesHook`

Defines `removeReferencesToVendoredSources()` which handles removing all
references to vendored sources from the installed binaries, which ensures that
nix does not consider the binaries as having a (runtime) dependency on the
sources themselves. It takes two positional arguments:
1. the installation directory for the output.
   * If not specified, the value of `$out` will be used
   * If `out` is not specified, an error will be raised
1. a path to the vendored sources
   * If not specified, the value of `$cargoVendorDir` will be used
   * If `cargoVendorDir` is not specified, an error will be raised
   * Note: it is expected that this directory has the exact structure as would
     be produced by `craneLib.vendorCargoDeps`

Any patched binaries on `aarch64-darwin` will be [signed](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/Introduction/Introduction.html). You can disable this functionality by setting `doNotSign`.

**Automatic behavior:** if `cargoVendorDir` is set and
`doNotRemoveReferencesToVendorDir` is not set, then
`removeReferencesToVendoredSources "$out" "$cargoVendorDir"` will be run as a
post install hook.

### `craneLib.replaceCargoLockHook`

Defines `replaceCargoLock()` which handles replacing or inserting a specified
`Cargo.lock` file in the current directory. It takes one positional argument:
1. a file which will be copied to `Cargo.lock` in the current directory
   * If not specified, the value of `$cargoLock` will be used
   * If `$cargoLock` is not set, an error will be raised

**Automatic behavior:** if `cargoLock` is set and
`doNotReplaceCargoLock` is not set, then `replaceCargoLock "$cargoLock"` will be
run as a pre patch hook.
