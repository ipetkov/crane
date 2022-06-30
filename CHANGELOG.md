# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## Unreleased

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

[0.5.0]: https://github.com/ipetkov/crane/compare/v0.4.1...v0.5.0
[0.4.1]: https://github.com/ipetkov/crane/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/ipetkov/crane/compare/v0.3.3...v0.4.0
[0.3.3]: https://github.com/ipetkov/crane/compare/v0.3.2...v0.3.3
[0.3.2]: https://github.com/ipetkov/crane/compare/v0.3.1...v0.3.2
[0.3.1]: https://github.com/ipetkov/crane/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/ipetkov/crane/compare/v0.2.1...v0.3.0
[0.2.1]: https://github.com/ipetkov/crane/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/ipetkov/crane/compare/v0.1.0...v0.2.0
