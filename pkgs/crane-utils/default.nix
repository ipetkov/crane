{
  lib,
  rustPlatform,
  writableTmpDirAsHomeHook,
}:

rustPlatform.buildRustPackage {
  pname = "crane-utils";
  version = "0.0.1";

  src = lib.sourceFilesBySuffices ./. [
    ".rs"
    ".toml"
    ".lock"
  ];
  cargoLock.lockFile = ./Cargo.lock;

  # NB: buildRustPackage doesn't set a CARGO_HOME location by default
  # which means it falls back on $HOME/.cargo (which points to a non-existent
  # /homeless-shelter/.cargo by default). On non-sandboxed builds this will
  # cause errors as Nix does not expect `/homeless-shelter` to exist. Hence
  # we ensure HOME is set to some writable path within the current build
  # https://github.com/ipetkov/crane/issues/815
  nativeBuildInputs = [
    writableTmpDirAsHomeHook
  ];
}
