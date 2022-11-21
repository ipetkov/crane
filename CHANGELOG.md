# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## Unreleased

### Added
* A new installation mode has been defined which symlinks identical cargo
  artifacts against previously generated ones. This allows for linear space
  usage in the Nix store across many chained derivations (as opposed to using a
  zstd compressed tarball which uses quadratic space across many chained
  derivations).

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
  to the
  `fetchurl` invocations for crates for that registry.
* `registryFromGitIndex` now uses shallow checkouts for better performance
* `registryFromDownloadUrl` and `registryFromGitIndex` now allow specifying
  `fetchurlExtraArgs` which will be forwarded to the `fetchurl` invocations for
  crates for that registry

### Fixed
* Unpacking a git repository now ignores duplicate crates to match cargo's
  behavior
* Sped up stripping references to source files

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
