{ internalCrateNameFromCargoToml
, lib
}:

args:
let
  throwMsg = throw ''
    unable to infer crate name and version. please ensure one of the following:
    - a Cargo.toml exists at the root of the source directory of the derivation
    - `cargoToml` is set to a path to the package's Cargo.toml
    - `cargoTomlContents` is set to the contents of the package's Cargo.toml
    - `pname` and `version` are explicitly set 
  '';

  origSrc = src:
    if src ? _isLibCleanSourceWith
    then src.origSrc
    else src;

  src = origSrc (args.src or throwMsg);
  cargoToml = args.cargoToml or (src + "/Cargo.toml");
  cargoTomlContents = args.cargoTomlContents or (
    if builtins.pathExists cargoToml
    then builtins.readFile cargoToml
    else throwMsg
  );

  # NB: if `src` is derived via `mkDummySrc` the Cargo.toml will contain store paths
  # (e.g. build script stubs), which the fromTOML does not like since the context isn't
  # threaded through (error is `the string ... is not allowed to refer to a store path`).
  # We can work around this by discarding the context before parsing the TOML since we don't
  # actually care about any dependency derivations, we just want to parse the name and version
  toml = builtins.fromTOML (builtins.unsafeDiscardStringContext cargoTomlContents);

  debugPath =
    if args ? cargoTomlContents
    then "provided Cargo.toml contents"
    else cargoToml;

  hint = lib.optionalString (!lib.elem (builtins.getEnv "NIX_ABORT_ON_WARN") [ "1" "true" "yes" ]) ''

    To find the source of this warning, rerun nix with:
    `NIX_ABORT_ON_WARN=1 nix --option pure-eval false --show-trace ...`
  '';

  traceMsg = tomlName: drvName: placeholder: workspaceHints: lib.flip lib.trivial.warn placeholder ''
    crane will use a placeholder value since `${tomlName}` cannot be found in ${debugPath}
    to silence this warning consider one of the following:
    - setting `${drvName} = "...";` in the derivation arguments explicitly
    - setting `package.${tomlName} = "..."` or ${lib.concatStringsSep " or " workspaceHints} in the root Cargo.toml
    - explicitly looking up the values from a different Cargo.toml via 
      `craneLib.crateNameFromCargoToml { cargoToml = ./path/to/Cargo.toml; }`
    ${hint}
  '';

  internalName = internalCrateNameFromCargoToml toml debugPath;
in
{
  pname = internalName.pname or (traceMsg "name" "pname" "cargo-package" [
    ''`package.metadata.crane.name` = "..."''
    ''`workspace.metadata.crane.name` = "..."''
  ]);
  version = internalName.version or (traceMsg "version" "version" "0.0.1" [
    ''`workspace.package.version` = "..."''
  ]);
}
