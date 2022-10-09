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
it across all of nixpkgs, consider using `overrideScope'`:

```nix
(mkLib pkgs).overrideScope' (final: prev: {
  cargo-tarpaulin = myCustomCargoTarpaulinVersion;
})
```

To overlay an entire rust toolchain (e.g. `cargo`, `rustc`, `clippy`, `rustfmt`,
etc.) consider using `overrideToolchain`.

## `lib`

### `lib.appendCrateRegistries`

`appendCrateRegistries :: [registry mapping] -> new lib`

Creates a new `lib` instance which will make additional registries available for
use when downloading crate sources. Each entry can be defined using:
* `registryFromDownloadUrl`: if you know the exact `dl` URL as defined in the
  registry's `config.json` file
* `registryFromGitIndex`: if you would like the download URL to be inferred from
  the index's source directly.

See the documentation on each function for more specifics.

```nix
newLib = lib.appendCrateRegistries [
  (lib.registryFromDownloadUrl {
    indexUrl = "https://github.com/rust-lang/crates.io-index";
    dl = "https://crates.io/api/v1/crates";
  })

  # Or, alternatively
  (lib.registryFromGitIndex {
    indexUrl = "https://github.com/Hirevo/alexandrie-index";
    rev = "90df25daf291d402d1ded8c32c23d5e1498c6725";
  })
];
```

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
  - Default value: `"cargo build --profile release"`
    * `CARGO_PROFILE` can be set on the derivation to alter which cargo profile
      is selected; setting it to `""` will omit specifying a profile
      altogether.
* `cargoCheckCommand`: A cargo (check) invocation to run during the derivation's build
  phase (in order to cache additional artifacts)
  - Default value: `"cargo check --profile release --all-targets"`
    * `CARGO_PROFILE` can be set on the derivation to alter which cargo profile
      is selected; setting it to `""` will omit specifying a profile
      altogether.
* `cargoExtraArgs`: additional flags to be passed in the cargo invocation (e.g.
  enabling specific features)
* `cargoTestCommand`: A cargo invocation to run during the derivation's check
  phase
  - Default value: `"cargo test --profile release"`
    * `CARGO_PROFILE` can be set on the derivation to alter which cargo profile
      is selected; setting it to `""` will omit specifying a profile
      altogether.
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
* `cargoExtraArgs`
* `cargoTestCommand`
* `dummySrc`

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
  - Default value: `"cargo build --profile release"`
    * `CARGO_PROFILE` can be set on the derivation to alter which cargo profile
      is selected; setting it to `""` will omit specifying a profile
      altogether.
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
* `jq`
* `removeReferencesTo`
* `removeReferencesToVendoredSourcesHook`

### `lib.cargoAudit`
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
  - Default value: `""`
* `cargoExtraArgs`: additional flags to be passed in the cargo invocation
  - Default value: `""`
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
* `cargoExtraArgs`

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
  - Default value: `"cargo build --profile release"`
    * `CARGO_PROFILE` can be set on the derivation to alter which cargo profile
      is selected; setting it to `""` will omit specifying a profile
      altogether.
* `cargoExtraArgs`: additional flags to be passed in the cargo invocation (e.g.
  enabling specific features)
  - Default value: `""`
* `cargoTestCommand`: A cargo invocation to run during the derivation's check
  phase
  - Default value: `"cargo test --profile release"`
    * `CARGO_PROFILE` can be set on the derivation to alter which cargo profile
      is selected; setting it to `""` will omit specifying a profile
      altogether.
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
* `doInstallCargoArtifacts`: controls whether cargo's `target` directory should
  be copied as an output
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
  - Default value: `""`

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

### `lib.cargoDoc`

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
  - Default value: `""`

#### Remove attributes
The following attributes will be removed before being lowered to
`mkCargoDerivation`. If you absolutely need these attributes present as
environment variables during the build, you can bring them back via
`.overrideAttrs`.
* `cargoDocExtraArgs`
* `cargoExtraArgs`

### `lib.cargoFmt`

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

### `lib.cargoNextest`

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
* `cargoNextestExtraArgs`: additional flags to be passed in the clippy invocation (e.g.
  deny specific lints)
  - Default value: `""`
* `partitions`: The number of separate nextest partitions to run. Useful if the
  test suite takes a long time and can be parallelized across multiple build
  nodes.
  - Default value: `1`
* `partitionType`: The kind of nextest partition to run (e.g. `"count"` or
  `"hash"` based).
  - Default value: `"count"`

#### Native build dependencies
The `cargo-nextest` package is automatically appended as a native build input to any
other `nativeBuildInputs` specified by the caller.

#### Remove attributes
The following attributes will be removed before being lowered to
`mkCargoDerivation`. If you absolutely need these attributes present as
environment variables during the build, you can bring them back via
`.overrideAttrs`.
* `cargoExtraArgs`
* `cargoNextestExtraArgs`
* `partitions`
* `partitionType`

### `lib.cargoTarpaulin`

`cargoTarpaulin :: set -> drv`

Create a derivation which will run a `cargo tarpaulin` invocation in a cargo
workspace.

Except where noted below, all derivation attributes are delegated to
`mkCargoDerivation`, and can be used to influence its behavior.
* `cargoArtifacts` will be instantiated via `buildDepsOnly` if not specified
  - `cargoTarpaulinExtraArgs` will be removed before delegating to `buildDepsOnly`
* `buildPhaseCargoCommand` will be set to run `cargo tarpaulin --profile release` in
  the workspace.
  - `CARGO_PROFILE` can be set on the derivation to alter which cargo profile is
    selected; setting it to `""` will omit specifying a profile altogether.
* `pnameSuffix` will be set to `"-tarpaulin"`

#### Optional attributes
* `cargoExtraArgs`: additional flags to be passed in the cargo invocation
  - Default value: `""`
* `cargoTarpaulinExtraArgs`: additional flags to be passed in the cargo
  tarpaulin invocation
  - Default value: `"--skip-clean --out Xml --output-dir $out"`

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

### `lib.cargoTest`

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
  - Default value: `""`
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

### `lib.cleanCargoSource`

`cleanCargoSource :: path or drv -> drv`

Cleans a source tree to omit things like version control directories as well
omit any non-Rust/non-cargo related files. Useful to avoid rebuilding a project
when unrelated files are changed (e.g. `flake.nix` or any other nix files).

The final output will be cleaned by both `cleanSourcesFilter` (from nixpkgs) and
`lib.filterCargoSources`. See each of them for more details on which files are
kept.

If it is necessary to customize which files are kept, a custom filter can be
written (which may want to also call `lib.filterCargoSources`) to achieve the
desired behavior.

```nix
lib.cleanCargoSource ./.
```

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

### `lib.crateRegistries`

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

### `lib.downloadCargoPackage`

`downloadCargoPackage :: set -> drv`

Download a packaged cargo crate (e.g. from crates.io) and prepare it for
vendoring.

#### Required input attributes
* `checksum`: the (sha256) checksum recorded in the Cargo.lock file
* `name`: the name of the crate
* `source`: the source key recorded in the Cargo.lock file
* `version`: the version of the crate

### `lib.downloadCargoPackageFromGit`

`downloadCargoPackageFromGit :: set -> drv`

Download a git repository containing a cargo crate or workspace, and prepare it
any crates it contains for vendoring.

#### Required input attributes
* `git`: the URL to the repository
* `rev`: the exact revision to check out

#### Optional attributes
* `ref`: the ref (i.e. branch or tag) to which `rev` belongs to. For branches it
  should be `"refs/head/${branch}"` and for tags it should be
  `"refs/tags/${tag}"`
  - Default value: `null`
* `allRefs`: whether all git refs should be fetched in order to look for the
  specified `rev`
  - Default value: `true` if `ref` is set to `null`, `false` otherwise

### `lib.findCargoFiles`

`findCargoFiles :: path -> set of lists`

Given a path, recursively search it for any `Cargo.toml`, `.cargo/config` or
`.cargo/config.toml` files.

```nix
lib.findCargoFiles ./src
# { cargoTomls = [ "..." ]; cargoConfigs = [ "..." ]; }
```

### `lib.filterCargoSources`

`filterCargoSources :: path -> string -> bool`

A source filter which when used with `cleanSourceWith` (from nixpkgs's `lib`)
will retain the following files from a given source:
- Cargo files (`Cargo.toml`, `Cargo.lock`, `.cargo/config.toml`, `.cargo/config`)
- Rust files (files whose name end with `.rs`)
- TOML files (files whose name end with `.toml`)

```nix
cleanSourceWith {
  src = ./.;
  filter = lib.filterCargoSources;
}
```

Note that it is possible to compose source filters, especially if
`filterCargoSources` omits files which are relevant to the build. For example:

```nix
let
  # Only keeps markdown files
  markdownFilter = path: _type: match ".*md$" path;
  markdownOrCargo = path: type:
    (markdownFilter path type) || (lib.filterCargoSources path type);
in
cleanSourceWith {
  src = ./.;
  filter = markdownOrCargo;
}
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

#### Optional attributes
* `buildPhase`: the commands used by the build phase of the derivation
  - Default value: the build phase will run `preBuild` hooks, print the cargo
    version, log and evaluate `buildPhaseCargoCommand`, and run `postBuild`
    hooks
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
* `checkPhaseCargoCommand`
* `installPhaseCommand`
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
* `zstd`

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
    in
    mkDummySrc {
      # The _entire_ source of the project. mkDummySrc will automatically
      # filter out irrelevant files as described above
      src = ./.;

      # Note that here we scope the path to just `./.cargo` and not any other
      # directories which may exist at the root of the project. Also note that
      # the entire path is inside of the `${ }` which ensures that the
      # derivation only consumes that directory. Writing `${./.}/.cargo` would
      # incorectly consume the entire source root, and therefore rebuild
      # everything when any file changes, which defeats artifact caching.
      #
      # Also note the `--no-target-directory` flag which ensures the results are
      # copied to `$out/.cargo` instead of something like `$out/HASH-.cargo`
      extraDummyScript = ''
        cp -r ${./.cargo} --no-target-directory $out/.cargo
      '';
    }
    ```


### `lib.overrideToolchain`

`overrideToolchain :: drv -> set`

A convenience method to override and use tools (like `cargo`, `clippy`,
`rustfmt`, `rustc`, etc.) from one specific toolchain. The input should be a
single derivation which contains all the tools as binaries. For example, this
can be the output of `oxalica/rust-overlay`.

```nix
crane.lib.${system}.overrideToolchain myCustomToolchain
```

### `lib.registryFromDownloadUrl`

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

#### Required attributes
* `dl`: the value of the `dl` entry in the registry's `config.json` file
* `indexUrl`: an HTTP URL to the index

```nix
lib.registryFromDownloadUrl {
  dl = "https://crates.io/api/v1/crates";
  indexUrl = "https://github.com/rust-lang/crates.io-index";
}
# { "registry+https://github.com/rust-lang/crates.io-index" = "https://crates.io/api/v1/crates/{crate}/{version}/download"; }
```

### `lib.registryFromGitIndex`

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

#### Required attributes
* `indexUrl`: an HTTP URL to the index
* `rev`: any git revision which contains the latest `config.json` definition

```nix
lib.registryFromGitIndex {
  url = "https://github.com/Hirevo/alexandrie-index";
  rev = "90df25daf291d402d1ded8c32c23d5e1498c6725";
}
# { "registry+https://github.com/Hirevo/alexandrie-index" = "https://crates.polomack.eu/api/v1/crates/{crate}/{version}/download"; }
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

Each unique crate index will be vendored as its own subdirectory within the
output of the derivation. A `config.toml` file will also be placed at the root
of the output which will contain the necessary configurations to point cargo to
the vendored directories (i.e. this configuration can be appended to the
`.cargo/config.toml` definition of the project).

#### Input attributes
* `src`: a directory which includes a Cargo.lock file at its root.
* `cargoLock`: a path to a Cargo.lock file
* `cargoLockContents`: the contents of a Cargo.lock file as a string

At least one of the above attributes must be specified, or an error will be
raised during evaluation.

### `lib.vendorCargoRegistries`

`vendorCargoRegistries :: set -> set`

Creates the derivations necessary to download all crates from all registries
referenced by a `Cargo.lock` file, and prepare the vendored directories which
cargo can use for subsequent builds without needing network access.

#### Input attributes
* `cargoConfigs`: a list of paths to all `.cargo/config.toml` files which may
  appear in the project
* `lockPackages`: a list of all `[[package]]` entries found in the project's
  `Cargo.lock` file (parsed via `builtins.fromTOML`)

#### Output attributes
* `config`: the configuration entires needed to point cargo to the vendored
  crates. This is intended to be appended to `$CARGO_HOME/config.toml` verbatim
* `sources`: an attribute set of all the newly created cargo sources' names to
  their location in the Nix store

### `lib.vendorGitDeps`

`vendorGitDeps :: set -> set`

Creates the derivations necessary to download all crates from all git
dependencies referenced by a `Cargo.lock` file, and prepare the vendored
directories which cargo can use for subsequent builds without needing network
access.

#### Input attributes
* `lockPackages`: a list of all `[[package]]` entries found in the project's
  `Cargo.lock` file (parsed via `builtins.fromTOML`)

#### Output attributes
* `config`: the configuration entires needed to point cargo to the vendored
  sources. This is intended to be appended to `$CARGO_HOME/config.toml` verbatim
* `sources`: an attribute set of all the newly created cargo sources' names to
  their location in the Nix store

### `lib.writeTOML`

`writeTOML :: String -> String -> drv`

Takes a file name and an attribute set, converts the set to a TOML document and
writes it to a file with the given name.

```nix
lib.writeTOML "foo.toml" { foo.bar = "baz"; }
# «derivation /nix/store/...-foo.toml.drv»
```

## Hooks

### `lib.cargoHelperFunctionsHook`

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

### `lib.configureCargoCommonVarsHook`

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

### `lib.configureCargoVendoredDepsHook`

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

### `lib.inheritCargoArtifactsHook`

Defines `inheritCargoArtifacts()` which will pre-populate cargo's artifact
directory using a previous derivation. It takes two positional arguments:
1. a path to the previously prepared artifacts
   * If not specified, the value of `$cargoArtifacts` will be used
   * If `cargoArtifacts` is not specified, an error will be raised
   * If the specified path is a directory which contains a file called
     `target.tar.zst`, then that file will be used during unpacking
   * The previously prepared artifacts are expected to be a zstd compressed
     tarball
1. the path to cargo's artifact directory, where the previously prepared
   artifacts should be unpacked
   * If not specified, the value of `$CARGO_TARGET_DIR` will be used
   * If `CARGO_TARGET_DIR` is not set, cargo's default target location  (i.e.
     `./target`) will be used.

**Automatic behavior:** if `cargoArtifacts` is set, then
`inheritCargoArtifacts "$cargoArtifacts" "$CARGO_TARGET_DIR"` will be run as a
post patch hook.

**Required nativeBuildInputs**: assumes `zstd` is available on the `$PATH`

### `lib.installCargoArtifactsHook`

Defines `prepareAndInstallCargoArtifactsDir()` which handles installing cargo's
artifact directory to the derivation's output. It takes two positional
arguments:
1. the installation directory for the output.
   * If not specified, the value of `$out` will be used
   * Cargo's artifact directory will be compressed as a reproducible tarball
     with zstd compression. It will be written to this directory and named
     `target.tar.zstd`
1. the path to cargo's artifact directory
   * If not specified, the value of `$CARGO_TARGET_DIR` will be used
   * If `CARGO_TARGET_DIR` is not set, cargo's default target location  (i.e.
     `./target`) will be used.

**Automatic behavior:** if `doInstallCargoArtifacts` is set to `1`, then
`prepareAndInstallCargoArtifactsDir "$out" "$CARGO_TARGET_DIR"` will be run as a
post install hook.

**Required nativeBuildInputs**: assumes `zstd` is available on the `$PATH`

### `lib.installFromCargoBuildLogHook`

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

### `lib.removeReferencesToVendoredSourcesHook`

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
     be produced by `lib.vendorCargoDeps`

**Automatic behavior:** if `cargoVendorDir` is set and
`doNotRemoveReferencesToVendorDir` is not set, then
`removeReferencesToVendoredSources "$out" "$cargoVendorDir"` will be run as a
post install hook.

**Required nativeBuildInputs**: assumes `remove-references-to` is available on the `$PATH`
