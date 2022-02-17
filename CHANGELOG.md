# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## Unreleased

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

[0.3.0]: https://github.com/ipetkov/crane/compare/v0.2.1...v0.3.0
[0.2.1]: https://github.com/ipetkov/crane/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/ipetkov/crane/compare/v0.1.0...v0.2.0
