# API Documentation
## `lib`

### `lib.buildDepsOnly`

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
  - Default value: `"cargo build --workspace --release"`
* `cargoCheckCommand`: A cargo (check) invocation to run during the derivation's build
  phase (in order to cache additional artifacts)
  - Default value: `"cargo build --workspace --release"`
* `cargoExtraArgs`: additional flags to be passed in the cargo invocation (e.g.
  enabling specific features)
* `cargoTestCommand`: A cargo invocation to run during the derivation's check
  phase
  - Default value: `"cargo test --workspace --release"`
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
* `cargoExtraArgs`
* `cargoTestCommand`

### `lib.buildPackage`

`buildPackage :: set -> drv`

A(n opinionated) version of `cargoBuild` which will install to the output any
binaries which were built by cargo in this invocation. All options understood by
`cargoBuild` apply here as well, with the only difference being some additional
book keeping necessary to log cargo's results and subsequently install from that
log.

#### Optional attributes
* `buildPhase`: the commands used by the build phase of the derivation
  - Default value: the build phase will run `preBuild` hooks, print the cargo
    version, log and evaluate `buildPhaseCargoCommand`, and run `postBuild`
    hooks
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
* `cargoBuildCommand`: A cargo invocation to run during the derivation's build
  phase
  - Default value: `"cargo build --workspace --release"`
* `cargoExtraArgs`: additional flags to be passed in the cargo invocation (e.g.
  enabling specific features)
  - Default value: `""`
* `doInstallCargoArtifacts`: controls whether cargo's `target` directory should
  be copied as an output
  - Default value: `false`
* `installPhase`: the commands used by the install phase of the derivation
  - Default value: the install phase will run `preInstall` hooks, look for a
    cargo build log and install all binary targets listed there, and run
    `postInstall` hooks

#### Native build dependencies and included hooks
The following hooks are automatically added as native build inputs:
* `installFromCargoBuildLogHook`

### `lib.cargoBuild`

`cargoBuild :: set -> drv`

Create a derivation which will build and test a cargo workspace.

The exact cargo command being run (or the arguments passed into it) can be
easily updated to suit your needs. If a project requires multiple cargo
invocations, they can either be run one after the other (as you'd expect in a
regular derivation), or they can be split out into separate derivations and
chained together via `cargoArtifacts` which would allow for more incremental
building and caching of the results.

Consider using `buildPackage` if all you need is to build the workspace and
install the resulting application binaries.

In addition to all default values being set as documented below, all derivation
attributes are delegated to `mkCargoDerivation`, and can be used to influence
its behavior.

#### Optional attributes
* `buildPhaseCargoCommand`: A command to run during the derivation's build
  phase. Pre and post build hooks will automatically be run.
  - Default value: `"${cargoBuildCommand} ${cargoExtraArgs}"`
* `cargoArtifacts`: A path (or derivation) which contains an existing cargo
  `target` directory, which will be reused at the start of the derivation.
  Useful for caching incremental cargo builds.
  - Default value: the result of `buildDepsOnly` after applying the arguments
    set (with the respective default values)
* `cargoBuildCommand`: A cargo invocation to run during the derivation's build
  phase
  - Default value: `"cargo build --workspace --release"`
* `cargoExtraArgs`: additional flags to be passed in the cargo invocation (e.g.
  enabling specific features)
  - Default value: `""`
* `cargoTestCommand`: A cargo invocation to run during the derivation's check
  phase
  - Default value: `"cargo test --workspace --release"`
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
* `cargoExtraArgs`
* `cargoTestCommand`

### `lib.cargoClippy`

`cargoClippy :: set -> drv`

Create a derivation which will run a `cargo clippy` invocation in a cargo
workspace.

Except where noted below, all derivation attributes are delegated to
`cargoBuild`, and can be used to influence its behavior.
* `cargoBuildCommand` will be set to run `cargo clippy` for all targets in the
  workspace.
* `cargoExtraArgs` will have `cargoClippyExtraArgs` appended to it
  - Default value: `""`
* `doCheck` is disabled
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
  - Default value: `""`
* `cargoExtraArgs`: additional flags to be passed in the cargo invocation (e.g.
  enabling specific features)
  - Default value: `""`
* `doInstallCargoArtifacts`: controls whether cargo's `target` directory should
  be copied as an output
  - Default value: `false`

#### Native build dependencies
The `clippy` package is automatically appended as a native build input to any
other `nativeBuildInputs` specified by the caller.

#### Remove attributes
The following attributes will be removed before being lowered to
`cargoBuild`. If you absolutely need these attributes present as
environment variables during the build, you can bring them back via
`.overrideAttrs`.
* `cargoClippyExtraArgs`

### `lib.cleanCargoToml`

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
lib.cleanCargoToml { cargoToml = ./Cargo.toml; }
# { dependencies = { byteorder = "*"; }; package = { edition = "2021"; name = "simple"; version = "0.1.0"; }; }
```

#### Input attributes
* `cargoToml`: a path to a Cargo.toml file
* `cargoTomlContents`: the contents of a Cargo.toml file as a string

At least one of the above attributes must be specified, or an error will be
raised during evaluation.

### `lib.crateNameFromCargoToml`

`crateNameFromCargoToml :: set -> set`

Extract a crate's name and version from its Cargo.toml file.

```nix
lib.crateNameFromCargoToml { cargoToml = ./Cargo.toml; }
# { pname = "simple"; version = "0.1.0"; }
```

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
  - Default value: `"unknown"` if the specified Cargo.toml file did not
    include a version

### `lib.downloadCargoPackage`

`downloadCargoPackage :: set -> drv`

Download a packaged cargo crate (e.g. from crates.io) and prepare it for
vendoring.

#### Required input attributes
* `checksum`: the (sha256) checksum recorded in the Cargo.lock file
* `name`: the name of the crate
* `source`: the source key recorded in the Cargo.lock file
* `version`: the version of the crate

### `lib.fromTOML`

`fromTOML :: String -> set`

Convert a TOML string to a Nix attribute set.

```nix
lib.fromTOML (builtins.readFile ./Cargo.toml)
# { package = { edition = "2021"; name = "simple"; version = "0.1.0"; }; }
```

### `lib.mkCargoDerivation`

`mkCargoDerivation :: set -> drv`

A thin wrapper around `stdenv.mkDerivation` which includes common hooks for
building a derivation using cargo. Except where noted below, all derivation
attributes are passed straight through, so any common derivation behavior can be
used as expected.

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
* `cargoVendorDir`: A path (or derivation) of vendored cargo sources which can
  be consumed without network access. Directory structure should basically
  follow the output of `cargo vendor`.
  - This can be prepared via `vendorCargoDeps`
* `checkPhaseCargoCommand`: A command (likely a cargo invocation) to run during
  the derivation's check phase. Pre and post check hooks will automatically be
  run.
* `pname`: the package name used for the derivation

#### Optional attributes
* `buildPhase`: the commands used by the build phase of the derivation
  - Default value: the build phase will run `preBuild` hooks, print the cargo
    version, log and evaluate `buildPhaseCargoCommand`, and run `postBuild`
    hooks
* `checkPhase`: the commands used by the check phase of the derivation
  - Default value: the check phase will run `preCheck` hooks, log and evaluate
    `checkPhaseCargoCommand`, and run `postCheck` hooks
* `doInstallCargoArtifacts`: controls whether cargo's `target` directory should
  be copied as an output
  - Default value: `true`
* `doRemapSourcePathPrefix`: Controls instructing rustc to remap the path prefix
  of any sources it captures (for example, this can include file names used in
  panic info). This is useful to omit any references to `/nix/store/...` from
  the final binary, as including them will make Nix pull in all sources when
  installing any binaries.
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
* `pnameSuffix`: a suffix appended to `pname`
  - Default value: `""`

#### Remove attributes
The following attributes will be removed before being lowered to
`stdenv.mkDerivation`. If you absolutely need these attributes present as
environment variables during the build, you can bring them back via
`.overrideAttrs`.

* `buildPhaseCargoCommand`
* `checkPhaseCargoCommand`
* `installPhaseCommand`
* `pnameSuffix`

#### Native build dependencies and included hooks
The `cargo` package is automatically appended as a native build input to any
other `nativeBuildInputs` specified by the caller, along with the following
hooks:
* `configureCargoCommonVarsHook`
* `configureCargoVendoredDepsHook`
* `inheritCargoArtifactsHook`
* `installCargoArtifactsHook`
* `remapSourcePathPrefixHook`

### `lib.mkDummySrc`

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

### `lib.toTOML`

`toTOML :: set -> String`

Convert an attribute set to a TOML string.

```nix
lib.toTOML { foo.bar = "baz"; }
# "[foo]\nbar = \"baz\""
```

### `lib.urlForCargoPackage`

`urlForCargoPackage :: set -> String`

Returns the URL for downloading a particular crate. For now, only crates.io is
supported.

#### Required input attributes
* `name`: the name of the crate
* `source`: the source key recorded in the Cargo.lock file
* `version`: the version of the crate

### `lib.vendorCargoDeps`

`vendorCargoDeps :: set -> drv`

Creates a derivation which will download all crates referenced by a Cargo.lock
file, and prepare a vendored directory which cargo can use for subsequent builds
without needing network access.

#### Input attributes
* `src`: a directory which includes a Cargo.lock file at its root.
* `cargoLock`: a path to a Cargo.lock file
* `cargoLockContents`: the contents of a Cargo.lock file as a string

At least one of the above attributes must be specified, or an error will be
raised during evaluation.

### `lib.writeTOML`

`writeTOML :: String -> String -> drv`

Takes a file name and an attribute set, converts the set to a TOML document and
writes it to a file with the given name.

```nix
lib.writeTOML "foo.toml" { foo.bar = "baz"; }
# «derivation /nix/store/...-foo.toml.drv»
```
