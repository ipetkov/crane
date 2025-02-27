# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## Unreleased

### Fixed
* `mkDummySrc` now supports embedded proc-macros.

### Fixed
* `buildTrunkPackage` no longer ignores `installPhase` and `installPhaseCommand` args.

## [0.20.2] - 2025-02-17

### Changed
* `craneUtils` (used internally for vendoring git dependencies) now uses
  `importCargoLock` to fetch its own dependencies instead of the (now
  deprecated) `fetchCargoTarball` method.

## [0.20.1] - 2025-02-08

### Added
* `cargoNextest` now supports passing `cargoNextestPartitionsExtraArgs` to each
  `cargo nextest` partition run.
* Add self-reference `craneLib` to crane lib instance.
* Add `removeReferencesToRustToolchainHook`, which, by default, removes
  references to the Rust toolchain from all installed binaries
  
### Changed
* `buildPackage` now includes `removeReferencesToRustToolchainHook` as a native
  dependency. To disable automatically removing references to the Rust
  toolchain, set `doNotRemoveReferencesToRustToolchain = true;`
* `mkCargoDerivation` now will also append the `rustc` package to the
  derivation's `nativeBuildInputs`

## [0.20.0] - 2024-12-21

### Changed
* **Breaking**: dropped compatibility for Nix versions below 2.24.10
* **Breaking**: dropped compatibility for nixpkgs-24.05
* **Breaking** (technically): `buildPackage`'s installation behavior has been
  split into two steps: binaries are now installed into a temporary directory as
  a post build hook (to avoid interference from the check phase clobbering
  resultant binaries with development features enabled) followed by an actual
  installation (from said directory) during the install phase. If you use a
  custom build phase with `buildPackage` you may need to ensure the additional
  post build hook defined in `installFromCargoBuildLogHook` runs (or follow the
  error messages to resolve any build issues).
* `mkDummySrc` has been reworked to match cargo's `autobin` detection logic,
  meaning that only real binary targets defined by the project will be dummified
  if they exist (no more injecting `src/bin/crane-dummy-*`). This does mean that
  adding a new bin target definition will invalidate caches and require
  rebuilding all dependencies once more. (If this is a frequent enough
  occurrence for your project to cause headaches, please open an issue!)

### Fixed
* `mkDummySrc` will deduplicate discovered and declared binary targets when
  dummifying sources
* `crateNameFromCargoToml` will ignore store contexts when parsing a Cargo.toml
  file (avoiding errors like `the string ... is not allowed to refer to a store
  path`).
* `vendorGitDeps` will perform a basic URL-decoding of git dependency entries in
  the `Cargo.lock` file since lockfiles now encode special characters starting
  at version 4

### Meta
* Dropped support for publishing releases to https://flakestry.dev/

## [0.19.4] - 2024-11-30

### Fixed
* `removeReferencesToVendoredSources` now deduplicates any found references to
  avoid pathological memory usage before removing them.
* `buildDepsOnly` will calculate fallback `pname`/`version`/`cargoVendorDir`
  attributes using `dummySrc` if it was specified (rather than attempting to use
  `src`)

## [0.19.3] - 2024-11-18
A republish of 0.19.2 which was incorrectly tagged.

## [0.19.2] - 2024-11-18

### Added
* Added a number of fileset helpers to more easily compose source filtering:
   * `fileset.cargoTomlAndLock`: for `Cargo.toml` and `Cargo.lock` files
   * `fileset.commonCargoSources`: for files commonly used by cargo projects
   * `fileset.configToml`: for `config.toml` files
   * `fileset.rust`: for `*.rs` files
   * `fileset.toml`: for `*.toml` files

### Fixed
* `buildTrunkPackage` will pass in `--release=true` (instead of just
  `--release`) for trunk versions 0.21 or higher to avoid argument ambiguities
* `buildTrunkPackage` will now correctly honor `buildPhaseCargoCommand` if
  specified (previously the value of `buildPhaseCommand` was incorrectly being
  used)
* `removeReferencesToVendoredSourcesHook` avoids referencing `/dev/fd`
  directly since it may not be present on certain platforms

## [0.19.1] - 2024-10-12

### Added

* `cargoDocTest` is now available as an alternative to `cargoTest` which runs
  only doc tests.

### Changed

* `buildDepsOnly` now sets `CRANE_BUILD_DEPS_ONLY` as an environment variable
  when it runs. Build hooks can use this as a shortcut to determine whether
  running inside of a `buildDepsOnly` derivation in case they need to tailor
  their behavior accordingly.

### Fixed
* Vendoring dependencies avoids creating malformed TOML configurations in
  situations where registry name/url definitions cannot be found. When this
  happens a warning will be printed out during evaluation to highlight the
  issue.

## [0.19.0] - 2024-09-25

### Added
* `taploFmt` is now available for checking TOML formatting

### Changed
* **Breaking** (technically): `buildPackage` no longer adds `jq` to
  `nativeBuildInputs` as doing so can result in rebuilding any `*-sys` crates
  which rely on `PKG_CONFIG_PATH` remaining stable
* **Breaking**: `downloadCargoPackageFromGit` now takes `hash` instead of
  `sha256` when specifying an output hash for the download
* `installFromCargoBuildLogHook` no longer assumes or requires that `jq` is
  available on `$PATH` and will instead directly reference `pkgs.jq`
* `downloadCargoPackageFromGit` will now set `fetchLFS = true` when fetching git
  repos with defined output hashes

### Fixed
* `cargoDoc` correctly honors `docInstallRoot` when specified
* `cargoDoc` falls back to installing from `./target/doc` even if
  `$CARGO_BUILD_TARGET` is set but `./target/$CARGO_BUILD_TARGET/doc` does not
  exist

### Removed
* The deprecated top-level (flake) attribute `lib` no longer exists. Please use
  `mkLib` with an instance of `pkgs` instead.

## [0.18.1] - 2024-08-22

### Fixed
* Fixed vendoring dependencies from an alternative registry which they
  themselves have dependencies on crates from _other_ registries.
* Fixed `cargoNextest`'s positioning of `cargoExtraArgs` to form a valid command
  invocation when specified.

## [0.18.0] - 2024-07-05

### Changed
* **Breaking**: dropped compatibility for Nix versions below 2.18.2
* **Breaking**: dropped compatibility for nixpkgs-23.11
* The guidance around using (both) `cleanCargoSource` and `path` has been
  updated. Namely, it is no longer necessary to call both (e.g.
  `craneLib.cleanCargoSource (craneLib.path ./.)`): it is recommended to either
  use `craneLib.cleanCargoSource ./.` directly (if the default source cleaning
  is desired) or `craneLib.path ./.` (if not).
* `overrideToolchain` has been updated to better handle cross-compilation
  splicing for a customized toolchain. This means that `overrideToolchain`
  should now be called with a function which constructs said toolchain for any
  given `pkgs` instantiation. For example: `craneLib.overrideToolchain (p:
  p.rust-bin.stable.latest.default)`

### Fixed
* The cross compilation example also hows how to set the `TARGET_CC` environment
  variable which may be required by some build scripts to function properly
* `vendorCargoDeps` and `crateNameFromCargoToml` do their best to avoid IFD when
  `src` is the result of `lib.cleanSourceWith` (and by extension
  `cleanCargoSource`)
* `removeReferencesToVendoredSources` handles the edge case where
  `cargoVendorDir` does not point to a path within the Nix store
* It is now possible to use `.overrideScope` to change what instance of
  `craneUtils` will be used during vendoring.

## [0.17.3] - 2024-06-02

### Fixed
* `removeReferencesToVendoredSources` correctly signs aarch64-darwin builds
  (which was accidentally broken in 0.17.2)

## [0.17.2] - 2024-05-26

### Fixed
* `removeReferencesToVendoredSources` has been optimized to search for source
  references only once. For derivations which install many files, this phase can
  run up to 99% faster than before.
* `cleanCargoToml` now cleans underscored versions of the same attributes (e.g.
  `lib.proc-macro` and `lib.proc_macro`)

## [0.17.1] - 2024-05-19

### Fixed
* `downloadCargoPackage` and `downloadCargoPackageFromGit` no longer run the
  fixup phase by default, avoiding issues with source directories and files
  being moved to different locations
* `downloadCargoPackage` now unpacks and installs from a fresh directory,
  avoiding having build environment files (like `env-vars`) appearing in the
  output

## [0.17.0] - 2024-05-18

### Added
* `cargoDoc` now supports `docInstallRoot` to influence which directory will be
  installed to `$out/share` (which can be useful when cross-compiling). By
  default `$CARGO_TARGET_DIR` and `$CARGO_BUILD_TARGET` (if set) will be taken
  into account
* `crateNameFromCargoToml` now supports selecting a derivation name by setting
  `package.metadata.crane.name` or `workspace.metadata.crane.name` in the root
  `Cargo.toml`
* `vendorCargoDeps`, `vendorCargoRegistries`, `vendorGitDeps`, and
  `vendorMultipleCargoDeps` now support arbitrary overrides (i.e. patching) at
  the individual crate/repo level when vendoring sources.

### Changed
* **Breaking** `cargoAudit` no longer accepts `cargoExtraArgs` (since it does
  not support the regular set of `cargo` flags like most cargo-commands do, it
  does not make much sense to propagate those flags through)
* `buildTrunkPackage` now sets `env.TRUNK_SKIP_VERSION_CHECK = "true";` if not
  specified

### Deprecations
* In the future, `crateNameFromCargoToml` will stop considering
  `workspace.package.name` in the root `Cargo.toml` when determining the crate
  name. This attribute is not recognized by cargo (which will emit its own
  warnings about it) and should be avoided going forward.
* In the future, `crane.lib.${system}` will be removed. Please switch to using
  `(crane.mkLib nixpkgs.lib.${system})` as an equivalent alternative.

## [0.16.6] - 2024-05-04

### Fixed
* Same as 0.16.5 but with the correct tag deployed to Flakestry/FlakeHub

## [0.16.5] - 2024-05-04

### Fixed
* Workspace inheritance for git dependencies now ignores (removes) all comments
  around dependency declarations to work around a mangling bug in `toml_edit`
  (see https://github.com/ipetkov/crane/issues/527 and
  https://github.com/toml-rs/toml/issues/691)

## [0.16.4] - 2024-04-07

### Added
* Added a warning if an unsupported version of nixpkgs is used

### Changed
* `cargoNextest` now supports setting `withLlvmCov` which will automatically run
  `cargo llvm-cov nextest`. Note that `withLlvmCov = true;` is (currently) only
  supported when `partitions = 1;`

### Fixed
* `inheritCargoArtifactsHook` and `installCargoArtifactsHook` now correctly
  handle the case when `CARGO_TARGET_DIR` is set to a nested directory
* Dependency vendoring now correctly takes unused patch dependencies into
  account

## [0.16.3] - 2024-03-19

### Changed
* Sources are now fetched [crates.io's
  CDN](https://blog.rust-lang.org/2024/03/11/crates-io-download-changes.html),
  following cargo's (new) default behavior.

### Fixed
* `vendorMultipleCargoDeps` correctly lists `registries` as an optional
  parameter

## [0.16.2] - 2024-02-21

### Changed
* `cleanCargoToml` now also strips out `[lints]` and `[workspace.lints]`
  definitions. This means avoiding unnecessarily rebuilding dependencies when
  the lint definitions change, and it avoids issues with failing to build
  dummified sources which might have violated a lint marked as `deny` or
  `forbid`

### Fixed
* Fixed an edge case with inheriting workspace dependencies where the workspace
  dependency is a string (e.g. `foo = "0.1.2"`) but the crate definition is a
  table (e.g. `foo = { workspace = true, optional = true }`)

## [0.16.1] - 2024-01-28

### Changed
* `buildDepsOnly` now ignores any outputs (besides the default `out`)

### Fixed
* `buildDepsOnly` no longer fails when workspace is configured with
  `#[deny(unused-extern-crates)]`
* `vendorCargoDeps` (and friends) are now much more friendly to
  cross-compilation definitions. Specifically, source vendoring will always
  build dependencies to run on the build machine (and not for the host we're
  cross compiling to).

## [0.16.0] - 2024-01-18

### Changed
* **Breaking**: dropped compatibility for Nix versions below 2.18.1
* **Breaking**: dropped compatibility for nixpkgs-23.05.
* `buildTrunkPackage` has a new argument, `wasm-bindgen-cli` must be set
  to avoid mismatching versions between the wasm-bindgen library and CLI tool.

### Fixed
* Workspace inheritance of `lints` in git dependencies is now correctly handled

## [0.15.1] - 2023-11-30

### Changed
* `buildDepsOnly` will now assume `cargoTestExtraArgs = "--no-run";` if not
  specified (since there is no point to trying to run tests with the stripped
  sources). To get the old behavior back, set `cargoTestExtraArgs = "";`

### Fixed
* `buildTrunkPackage`'s `preConfigure` script to fail quicker with a more
  obvious error message if dependencies at not appropriately met

## [0.15.0] - 2023-11-05

### Added
* `cargoDeny` added for running [`cargo-deny`](https://github.com/EmbarkStudios/cargo-deny).
* `installCargoArtifactsHook` will now pass along the contents of
  `$zstdCompressionExtraArgs` as arguments to `zstd` when compressing artifacts.
  This allows for tailoring compression behavior, for example, by setting
  `zstdCompressionExtraArgs = "-19";` on the derivation.

### Changed
* The `use-zstd` artifact installation mode now uses a chained, incremental
  approach to avoid redundancy. Old behavior (taking a full snapshot of the
  cargo artifacts) can be achieved by setting `doCompressAndInstallFullArchive =
  true`.
* The default `installCargoArtifactsMode` has been changed to `use-zstd`,
  meaning cargo artifacts will be compressed to a series of incremental, zstd
  compressed tarballs across derivations. To get the old behavior back, set
  `installCargoArtifactsMode = "use-symlink"` to any derivation which produces
  cargo artifacts.
* All dependencies (outside of `nixpkgs`) have been dropped from the (main)
  flake.lock file so they do not pollute downstream projects' lock files.

### Fixed
* `mkDummySrc` now properly handles file cleaning (and file including) when a
  build is invoked with a `--store ...` override

## [0.14.3] - 2023-10-17

### Changed
* `craneUtils` will now be built with the `rustPlatform` provided by nixpkgs
  instead of the currently configured toolchain. This should hopefully result in
  fewer surprises for those testing with really old MSRV toolchains.
* `devShell` will now additionally include `clippy` and `rustfmt` from the
  currently configured toolchain

### Fixed
* `replaceCargoLockHook` now runs as a `prePatch` hook (rather
  than `postUnpack`) which correctly replaces the `Cargo.lock` in the source
  directory rather than the parent directory

## [0.14.2] - 2023-10-15

### Added
* `replaceCargoLockHook` can now be used to easily replace or insert a
  `Cargo.lock` file in the current derivation

### Changed
* `cargoAudit` will pass `--ignore yanked` by default if `cargoAuditExtraArgs`
  are not specified. This is because `cargo-audit` cannot check for yanked
  crates from inside of the sandbox. To get the old behavior back, set
  `cargoAuditExtraArgs = "";`.

### Fixed
* Fixed handling of Cargo workspace inheritance for git-dependencies where said
  crate relies on reading non-TOML metadata (i.e. comments) from its Cargo.toml
  at build time. ([#407](https://github.com/ipetkov/crane/pull/407))
* Fixed handling of dummy target names to avoid issues with `cargo doc`.
  ([#410](https://github.com/ipetkov/crane/pull/410))
* When using `installCargoArtifactsMode = "use-zstd";` all files will be marked
  as user-writable while compressing
* `removeReferencesToVendoredSources` now signs `aarch64-darwin` binaries. ([#418](https://github.com/ipetkov/crane/pull/418))

## [0.14.1] - 2023-09-23

### Fixed

* Fixed a bug where `buildPackage` would fail to inherit artifacts from
  dependency crates if `cargoArtifacts` was not explicitly specified.

## [0.14.0] - 2023-09-21

### Added
* Added `devShell`, a thin wrapper around `pkgs.mkShell` which automatically
  provides `cargo` and `rustc`.
* Added the ability to specify output hashes of git dependencies for fully
  offline evaluations. The `outputHashes` attribute can now be optionally
  specified in `vendorCargoDeps`, `vendorGitDeps`, `vendorMultipleCargoDeps`, or
  anything else which delegates to them.

### Changed
* **Breaking** (technically): `buildDepsOnly`, `buildPackage`, `cargoBuild`,
  `cargoClippy`, `cargoDoc`, `cargoLlvmCov`, and `cargoTest`'s defaults have
  been changed such that if `cargoExtraArgs` have not been set, a default value
  of `--locked` will be used. This ensures that a project's committed
  `Cargo.lock` is exactly what is expected (without implicit changes at build
  time) but this may end up rejecting builds which were previously passing. To
  get the old behavior back, set `cargoExtraArgs = "";`
* **Breaking**: `cargoDoc` will no longer install cargo artifacts by default.
  Set `doInstallCargoArtifacts = true;` to get the old behavior back.
* `cargoDoc` will now install generated documentation in `$out/share/doc`
* Fixed a bug when testing proc macro crates with `cargoNextest` on macOS.
  ([#376](https://github.com/ipetkov/crane/pull/376))
* Replaced various internal usages of `runCommandLocal` with `runCommand` for
  more optimal behavior when downloading cached artifacts

## [0.13.1] - 2023-08-22

### Changed
* `buildTrunkPackage` will now use `dart-sass` instead of `nodePackages.sass`
* Vendoring git dependencies will now always resolve symlinks inside of a
  crate's directory. This allows for symlinks inside of a crate's directory to
  possibly refer to files at the root of the git repo itself (via symlink) and
  have those contents preserved during vendoring.

## [0.13.0] - 2023-08-07

### Added
* `buildPackage` now supports installing `dylib` targets
* Added support for sparse registries

### Changed
* **Breaking**: dropped compatibility for Nix versions below 2.13.3
* **Breaking**: dropped compatibility for nixpkgs-22.05. nixpkgs-23.05 and
* **Breaking** (technically): if `buildPackage` is called _without_ setting
  `cargoArtifacts`, the default `buildDepsOnly` invocation will now stop running
  any installation hooks
* **Breaking** (technically): `buildPackage` no longer installs cargo binary
  dependencies (i.e. when the `bindeps` feature is used) by default
* `inheritCargoArtifactsHook` will now symlink dependency `.rlib` and `.rmeta`
  files. This means that derivations which reuse existing cargo artifacts will
  run faster as fewer files (and bytes!) need to be copied around. To disable
  this behavior, set `doNotLinkInheritedArtifacts = true;`.
* `cargoTarpaulin` will now set `doNotLinkInheritedArtifacts = true;` unless
  otherwise specified
* Update `crane-utils` dependencies for successful build in nightly Rust (2023-06-28)

## [0.12.2] - 2023-06-06

### Added
* Added support for the [Trunk](https://trunkrs.dev) wasm app build tool

### Changed
* `resolver` key is no longer cleaned from Cargo.toml

### Fixed
* `buildTrunkPackage` will now strip references to store files by default
* `buildTrunkPackage` will now set the right `wasm-opt` version

## [0.12.1] - 2023-04-10

### Changed
* **Breaking**: When setting a default value for `cargoArtifacts`,
  `buildPackage` will now ignore `installPhase` and `installPhaseCommand` when
  calling `buildPackage`. To bring back the old behavior, please specify
  `cargoArtifacts` explicitly

### Added
* `vendorMultipleCargoDeps` can now be used to vendor crates from multiple
  distinct `Cargo.lock` files. Notably this allows for building the standard
  library (via `-Z build-std` or equivalent) since both the project's
  and the Rust toolchain's `Cargo.lock` files can be vendored together

### Changed
* `vendorCargoRegistries` now accepts a `registries` parameter from the caller.
  If not specified, it will be computed via `cargoConfigs`. Also `cargoConfigs`
  is now an optional parameter which will default to `[]` if not specified.

### Fixed
* `vendorCargoDeps` correctly accepts arguments which have _not_ set `src`, so
  long as one of `cargoLock`, `cargoLockContents`, or `cargoLockParsed` is set

## [0.12.0] - 2023-03-19

### Added

* Add a stubbed binary target to each "dummy" crate generated to support
["artifact dependencies" nightly feature](https://doc.rust-lang.org/cargo/reference/unstable.html#artifact-dependencies)
in case a crate is used as `bin` artifact dependency.
* Add `cargoLlvmCov` to run `cargo llvm-cov`
* Add `cargoLockParsed` option to `vendorCargoDeps` to support `Cargo.lock`
files parsed as nix attribute sets.
* `craneLib.path` can now be used as a convenience wrapper on (or drop in
  replacement of) `builtins.path` to ensure reproducible results whenever paths
  like `./.` or `./..` are used directly.

### Changed
* **Breaking** (technically): `mkCargoDerivation` will remove the following
  attributes before lowering to `mkDerivation`: `cargoLock`, `cargoLockContents`
  and `cargoLockParsed`. If your derivation needs these values to be present
  they can be explicitly passed through via `.overrideAttrs`
  `buildDepsOnly` as `dummySrc` will take priority
* The API docs have been updated to refer to `craneLib` (instead of just `lib`)
  to avoid ambiguities with `pkgs.lib`.
* cargo is now invoked with `--release` when `$CARGO_PROFILE == release` instead
  of passing in `--profile release` to better support tools which do not
  understand the latter

### Fixed
* Fixed support for projects depending on crates utilising per-target workspace dependencies.

## [0.11.3] - 2023-02-19

### Fixed
* Fixed an unintentional cache invalidation whenever `buildDepsOnly` would run
  on an unfiltered source (like `src = ./.;`).

### Changed
* A warning will now be emitted if a derivation's `pname` or `version`
  attributes are not set and the value cannot be loaded from the derivation's
  root `Cargo.toml`. To resolve it consider setting `pname = "...";` or `version
  = "...";` explicitly on the derivation.
* A warning will now be emitted if `src` and `dummySrc` are passed to
  `buildDepsOnly` as `dummySrc` will take priority

## [0.11.2] - 2023-02-11

### Fixed
* `buildPackage` is more tolerant of misbehaving proc macros which write to
  stdout during the build

## [0.11.1] - 2023-01-21

### Changed
* Documented and made it easier to build a cargo workspace located in a
  subdirectory of the source root

### Fixed
* Previously compiled build scripts now maintain their executable bit when
  inherited
* Workspace inheritance in git dependencies is now correctly handled

## [0.11.0] - 2022-12-26

### Added
* Documentation is now available at [crane.dev](https://crane.dev)

### Changed
* **Breaking**: dropped compatibility for Nix versions below 2.11.0
* **Breaking**: dropped compatibility for nixpkgs-22.05. nixpkgs-22.11 and
  nixpkgs-unstable are fully supported
* Zstd compression of cargo artifacts now defaults to using as many cores as
  `$NIX_BUILD_CORES` allows for (or all available cores if it isn't defined)
* Dummy sources now attempt to use the same name as their original source (minus
  the Nix store path and hash) to minimize errors with build scripts which
  expect their full path to not change between runs

## [0.10.0] - 2022-12-01

### Added
* A new installation mode has been defined which symlinks identical cargo
  artifacts against previously generated ones. This allows for linear space
  usage in the Nix store across many chained derivations (as opposed to using a
  zstd compressed tarball which uses quadratic space across many chained
  derivations).
* `mkDummySrc` optionally accepts a `dummyrs` argument which allows for
  customizing the contents of the dummy Rust files that will be generated.

### Changed
* **Breaking**: all cargo-based derivations will now default to using symlinking
  their installed artifacts together instead of using zstd compressed tarballs.
  To get the old behavior back, set `installCargoArtifactsMode = "use-zstd";` in
  the derivation.
  - Note that `buildPackage` will continue to use zstd compressed tarballs while
    building dependencies (unless either of `cargoArtifacts` or
    `installCargoArtifactsMode` is defined, in which case they will be honored)
* **Breaking**: the format for defining crate registries has been changed: each
  registry URL should map to a set containing a `downloadUrl` attribute. This
  set may also define `fetchurlExtraArgs` (another set) which will be forwarded
  to the `fetchurl` invocations for crates for that registry.
* **Breaking** (technically): `buildDepsOnly` will now only default to running
  `cargo check` with the `--all-targets` flag only if `doCheck = true;` is set on
  the derivation (otherwise the flag is omitted). To get the previous behavior
  back simply set `cargoCheckExtraArgs = "--all-targets";`.
* `registryFromGitIndex` now uses shallow checkouts for better performance
* `registryFromDownloadUrl` and `registryFromGitIndex` now allow specifying
  `fetchurlExtraArgs` which will be forwarded to the `fetchurl` invocations for
  crates for that registry

### Fixed
* Unpacking a git repository now ignores duplicate crates to match cargo's
  behavior
* Sped up stripping references to source files
* Dummy sources now import the `core` crate more robustly (playing more nicely
  with `cargo-hakari`)
* Building a crate's dependencies automatically works for uefi targets

## [0.9.0] - 2022-10-29

### Changed
* **Breaking**: all setup hooks have been removed from the `packages` flake
  output. They can still be accessed via the `lib` flake output.
* **Breaking**: `cargoBuild` now only runs `cargo build` in a workspace, tests
  are no longer run
* **Breaking**: `buildDepsOnly` does not automatically imply the `--all-targets`
  flag when invoking `cargo check`. Use `cargoCheckExtraArgs` to control this
* `buildDepsOnly` now accepts `cargoCheckExtraArgs` for passing additional
  arguments just to the `cargo check` invocation. By default `--all-targets`
  will be used
* `buildDepsOnly` now accepts `cargoTestExtraArgs` for passing additional
  arguments just to the `cargo test` invocation
* `buildPackage` now delegates to `mkCargoDerivation` instead of `cargoBuild`

### Fixed
* `crateNameFromCargoToml` now takes workspace inheritance into account. If a
  crate does not specify `package.version` in its (root) Cargo.toml but does
  specify `workspace.package.version` then the latter will be returned.
* Freestanding (`#![no_std]`) targets are now supported

## [0.8.0] - 2022-10-09

### Added
* `cargoTest` can now be used for only running the tests of a workspace

### Changed
* **Breaking** (technically): build hooks now expect helper tools (like `cargo`,
  `jq`, `zstd`, etc.) to be present on the path instead of substituting a
  reference to a (possibly different) executable in the store.
* `mkCargoDerivation` now automatically vendors dependencies if `cargoVendorDir`
  is not defined
* `mkCargoDerivation` now automatically populates `pname` and `version` (via
  `crateNameFromCargoToml`) if they are not specified
* `mkCargoDerivation` now defaults to an empty `checkPhaseCargoCommand` if not
  specified
* `cargoAudit` now delegates to `mkCargoDerivation` instead of `cargoBuild`
* `cargoClippy` now delegates to `mkCargoDerivation` instead of `cargoBuild`
* `cargoDoc` now delegates to `mkCargoDerivation` instead of `cargoBuild`
* `cargoFmt` now delegates to `mkCargoDerivation` instead of `cargoBuild`
* `cargoNextest` now delegates to `mkCargoDerivation` instead of `cargoBuild`
* `cargoTarpaulin` now delegates to `mkCargoDerivation` instead of `cargoBuild`

### Fixed
* Installing binaries now uses the same version of cargo as was used to build
  the package (instead of using whatever version is present in nixpkgs)

### Deprecated
* The `packages` flake output has been deprecated. All setup hooks can be
  accessed via the `lib` flake output (or via the result of the `mkLib` flake
  output)

## [0.7.0] - 2022-09-28

## Added
* `cargoDoc` can now be used for building the documentation of a workspace
* `cleanCargoSource` can now be used to filter sources to only include cargo and
  Rust files (and avoid rebuilds when irrelevant files change).
  `filterCargoSources` is the underlying filter implementation and can be
  composed with other filters
* `removeReferencesToVendoredSourcesHook` defines a post-install hook which will
  remove any references to vendored sources from any installed binaries. Useful
  for preventing nix from considering the binaries as having a (runtime)
  dependency on said sources

## Changed
* **Breaking**: `mkCargoDerivation` now includes a default `configurePhase`
  which does nothing but run the `preConfigure` and `postConfigure` hooks. This
  is done to avoid breaking builds by including puts happen to have setup-hooks
  which try to claim the configure phase (such as `cmake`). To get the old
  behavior back, set `configurePhase = null;` in the derivation.
* `mkCargoDerivation` (along with any of its callers like `cargoBuild`,
  `buildPackage`, etc.) now accept a `stdenv` argument which will override the
  default environment (coming from `pkgs.stdenv`) for that particular derivation
* `mkDummySrc` now accepts `extraScript` which can be used to run a custom
  script, and therefore customize what the dummy source contains
* `buildDepsOnly` now accepts `dummySrc` as a way to directly pass in the dummy
  source to be used. Automatically derived via `args.src` if not specified.

## Fixed
* `cargoAudit` properly keeps any `audit.toml` files when cleaning the source
* `buildPackage` now has more robust checks to ensure that all references to
  vendored sources are removed after installation (which avoids consumers of the
  final binaries having to download the sources as well)
* `mkDummySrc` how handles build scripts in a manner which ensures cargo runs
  the real script later (instead of thinking it has not changed)

## [0.6.0] - 2022-09-07

### Added
* Added `cargoNextest` for running tests via [cargo-nextest](https://nexte.st/)
* Added `cargoAudit` for running [cargo-audit](https://crates.io/crates/cargo-audit)
  with a provided advisory database instance.

### Changed
* **Breaking**: the `--workspace` flag is no longer set for all cargo commands
  by default. The previous behavior can be recovered by setting `cargoExtraArgs
  = "--workspace";` in any derivation.
* **Breaking**: the `$CARGO_PROFILE` environment variable can be used to specify
  which cargo-profile all invocations use (by default `release` will be used).
  Technically breaking if the default command was overridden for any derivation;
  set `CARGO_PROFILE = "";` to avoid telling cargo to use a release build.
* **Breaking**: `cargoTarpaulin` will use the release profile by default
* **Breaking**: `cargoClippy`'s `cargoClippyExtraArgs` now default to
  `"--all-targets"` instead of being specified as the cargo command itself. If
  you have set `cargoClippyExtraArgs` to an explicit value and wish to retain
  the previous behavior you should prepend `"--all-targets"` to it.
* **Breaking**: `remapSourcePathPrefixHook` and the `doRemapSourcePathPrefix`
  option have been removed, and the behavior of `buildPackage` has been updated
  to break false dependencies on the crate sources from the final binaries
  (which was the old behavior of the `doRemapSourcePathPrefix` option). To
  disable this behavior, set the `doNotRemoveReferencesToVendorDir` environment
  variable to any non-empty string.
* All cargo invocations made during the build are automatically logged
* Vendoring git dependencies will throw a descriptive error message if a locked
  revision is missing from `Cargo.lock` and a hint towards resolution

### Fixed
* **Breaking**: `vendorGitDeps` will only include crates referenced by the
  `Cargo.lock` file, meaning any extraneous crates which happen to be present in
  the git repository will be ignored.

## [0.5.1] - 2022-07-20

### Added
* Added `.overrideToolchain` as a convenience for using a custom rust toolchain

### Fixed
* Fixed an issue where `mkDummySrc` would produce incorrect results for filtered
  sources: #46

## [0.5.0] - 2022-06-12

### Changed
* **Breaking**: dropped compatibility for Nix versions below 2.8.1
* **Breaking**: updated all flake attributes to follow the new `.default`
  guidance as per Nix's warnings. Specifically:
  * Crane's default overlay is now available at `.overlays.default` (previously
    `.overlay`)
  * All templates now use `{app,devShells,packages}.default` as well
* **Breaking**: `lib.fromTOML` and `lib.toTOML` have been removed in favor of
  `builtins.fromTOML`
* Improved support for consuming `crane` without using flakes
* The `nix-std` dependency has been dropped

## [0.4.1] - 2022-05-29

### Fixed
* Dummy source derivations go to greater lengths to only depend on the files
  they consume. Specifying the entire flake source as an input (e.g. via
  `buildPackage { src = self; }`) now avoids rebuilding everything from scratch
  whenever _any_ file is changed. #28

## [0.4.0] - 2022-05-10

### Changed
* **Breaking**: the previously named `utils` flake input has been renamed to
  `flake-utils`
* `buildDepsOnly` now adds `--all-targets` to the default `cargo
  check` invocation. This allows caching all artifacts (including from
  dev-dependencies) such that tools like clippy don't have to generate them
  every time they run.
* Templates now use the newer flake format accepted by Nix 2.8 (e.g.
  `{packages,overlays,devShells}.default`, etc.)

### Fixed
* Fixed project and template flakes to avoid superfluous follows declaration for
  `flake-utils`
* Fixed quoting of relative paths to allow building with external sources

## [0.3.3] - 2022-02-24

### Fixed
* Use `lib.groupBy` if `builtins.groupBy` isn't available (i.e. if a Nix version
  earlier than 2.5 is used)
* The cross compilation example also hows how to set the `HOST_CC` environment
  variable which may be required by some build scripts to function properly

## [0.3.2] - 2022-02-18

### Fixed
* Fixed handling git dependencies whose locked revision is not on the
  repository's main branch

## [0.3.1] - 2022-02-17

### Added
* Added template and example for cross compiling to other platforms
* Added template and example for building static binaries using musl

### Changed
* `cargoClippy` and `cargoTarpaulin` will install cargo artifacts by default (or
  install an empty `target` directory if there are none). This allows for more
  easily chaining derivations if doing so is desired.
  - This can be disabled by setting `doInstallCargoArtifacts = false;` in the
    derivation

### Fixed
* Fixed an issue where cross compiling would try to needlessly cross compile
  rustc and cargo themselves

## [0.3.0] - 2022-02-11

### Added
* `downloadCargoPackageFromGit` has been added to handle downloading and
  unpacking a cargo workspace from a git repository
* `vendorCargoRegistries` has been added to handle vendoring crates from all
  registries used in a `Cargo.lock` file
* `vendorGitDeps` has been added to handle vendoring crates from all git sources
  used in a `Cargo.lock` file

### Changed
* `vendorCargoDeps` now automatically handles git dependencies by default
  - Git dependencies will be vendored as another source in the output derivation
  - The cargo configuration is done such that the sources are available to use
    when it decides, without overriding that crate for the entire workspace
    * For example, if your workspace contains a crate only used for testing
      which has a git dependency of a crate used by other parts of the
      workspace, then only that crate will use the git dependency. The rest of
      the workspace will continue to use the crates.io version, just like cargo
      behaves when used outside of Nix.

## [0.2.1] - 2022-02-11
### Changed
* `cargoFmt` will install cargo artifacts by default (or install an empty
  `target` directory if there are none). This allows for more easily chaining
  derivations if doing so is desired.
  - This can be disabled by setting `doInstallCargoArtifacts = false;` in the
    derivation

## [0.2.0] - 2022-01-30

### Added
* Support for alternative cargo registries

### Changed
* `urlForCargoPackage` now takes configured registries into account when
  downloading crate sources
* **Breaking**: `vendorCargoDeps` now vendors each unique registry as a subdirectory within
  the derivation's output. A `config.toml` file is also placed at the output
  root which contains the necessary configurations to point cargo at the
  vendored sources.
* `configureCargoVendoredDepsHook` is now aware of the updated `vendorCargoDeps`
  output format, and will use the `config.toml` file it generates if it is
  present. Otherwise it will fall back to the previous behavior (which is treat
  the entire directory as only vendoring crates.io).
* Source vendoring now uses `runCommandLocal` (instead of `runCommand`) to
  reduce network pressure in trying to fetch results which can quickly be built
  locally
* Searching for `Cargo.toml` or `.cargo/config.toml` files is now done more
  efficiently

## 0.1.0 - 2022-01-22
- First release

[0.20.1]: https://github.com/ipetkov/crane/compare/v0.20.0...v0.20.1
[0.20.0]: https://github.com/ipetkov/crane/compare/v0.19.4...v0.20.0
[0.19.4]: https://github.com/ipetkov/crane/compare/v0.19.3...v0.19.4
[0.19.3]: https://github.com/ipetkov/crane/compare/v0.19.2...v0.19.3
[0.19.2]: https://github.com/ipetkov/crane/compare/v0.19.1...v0.19.2
[0.19.1]: https://github.com/ipetkov/crane/compare/v0.19.0...v0.19.1
[0.19.0]: https://github.com/ipetkov/crane/compare/v0.18.1...v0.19.0
[0.18.1]: https://github.com/ipetkov/crane/compare/v0.18.0...v0.18.1
[0.18.0]: https://github.com/ipetkov/crane/compare/v0.17.3...v0.18.0
[0.17.3]: https://github.com/ipetkov/crane/compare/v0.17.2...v0.17.3
[0.17.2]: https://github.com/ipetkov/crane/compare/v0.17.1...v0.17.2
[0.17.1]: https://github.com/ipetkov/crane/compare/v0.17.0...v0.17.1
[0.17.0]: https://github.com/ipetkov/crane/compare/v0.16.6...v0.17.0
[0.16.6]: https://github.com/ipetkov/crane/compare/v0.16.5...v0.16.6
[0.16.5]: https://github.com/ipetkov/crane/compare/v0.16.4...v0.16.5
[0.16.4]: https://github.com/ipetkov/crane/compare/v0.16.3...v0.16.4
[0.16.3]: https://github.com/ipetkov/crane/compare/v0.16.2...v0.16.3
[0.16.2]: https://github.com/ipetkov/crane/compare/v0.16.1...v0.16.2
[0.16.1]: https://github.com/ipetkov/crane/compare/v0.16.0...v0.16.1
[0.16.0]: https://github.com/ipetkov/crane/compare/v0.15.1...v0.16.0
[0.15.1]: https://github.com/ipetkov/crane/compare/v0.15.0...v0.15.1
[0.15.0]: https://github.com/ipetkov/crane/compare/v0.14.3...v0.15.0
[0.14.3]: https://github.com/ipetkov/crane/compare/v0.14.2...v0.14.3
[0.14.2]: https://github.com/ipetkov/crane/compare/v0.14.1...v0.14.2
[0.14.1]: https://github.com/ipetkov/crane/compare/v0.14.0...v0.14.1
[0.14.0]: https://github.com/ipetkov/crane/compare/v0.13.1...v0.14.0
[0.13.1]: https://github.com/ipetkov/crane/compare/v0.13.0...v0.13.1
[0.13.0]: https://github.com/ipetkov/crane/compare/v0.12.2...v0.13.0
[0.12.2]: https://github.com/ipetkov/crane/compare/v0.12.1...v0.12.2
[0.12.1]: https://github.com/ipetkov/crane/compare/v0.12.0...v0.12.1
[0.12.0]: https://github.com/ipetkov/crane/compare/v0.11.3...v0.12.0
[0.11.3]: https://github.com/ipetkov/crane/compare/v0.11.2...v0.11.3
[0.11.2]: https://github.com/ipetkov/crane/compare/v0.11.1...v0.11.2
[0.11.1]: https://github.com/ipetkov/crane/compare/v0.11.0...v0.11.1
[0.11.0]: https://github.com/ipetkov/crane/compare/v0.10.0...v0.11.0
[0.10.0]: https://github.com/ipetkov/crane/compare/v0.9.0...v0.10.0
[0.9.0]: https://github.com/ipetkov/crane/compare/v0.8.0...v0.9.0
[0.8.0]: https://github.com/ipetkov/crane/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/ipetkov/crane/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/ipetkov/crane/compare/v0.5.1...v0.6.0
[0.5.1]: https://github.com/ipetkov/crane/compare/v0.5.0...v0.5.1
[0.5.0]: https://github.com/ipetkov/crane/compare/v0.4.1...v0.5.0
[0.4.1]: https://github.com/ipetkov/crane/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/ipetkov/crane/compare/v0.3.3...v0.4.0
[0.3.3]: https://github.com/ipetkov/crane/compare/v0.3.2...v0.3.3
[0.3.2]: https://github.com/ipetkov/crane/compare/v0.3.1...v0.3.2
[0.3.1]: https://github.com/ipetkov/crane/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/ipetkov/crane/compare/v0.2.1...v0.3.0
[0.2.1]: https://github.com/ipetkov/crane/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/ipetkov/crane/compare/v0.1.0...v0.2.0
