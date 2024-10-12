## Controlling whether or not hooks run during `buildDepsOnly`

A typical project configuration will build a workspace's dependencies (without
the actual sources) during the `buildDepsOnly` derivation, and later build the
project's sources in a second derivation. Sometimes this results in problems if
a build hook is accidentally configured to run in both derivations but expects
to use the real sources, for example.

### Solution 1: explicitly configure the arguments to each derivation

```nix
let
  # Explicitly split out common arguments
  commonArgs = {
    src = ./.;
    # etc.
  };

  # Then explicitly define the arguments to `buildDepsOnly`
  cargoArtifacts = craneLib.buildDepsOnly (commonArgs // {
    postConfigure = ''
      echo 'I am a hook which must only run during buildDepsOnly'
    '';
  });
};
in
craneLib.buildPackage (commonArgs // {
  inherit cargoArtifacts;
  preBuild = ''
    echo 'I am a hook which must run with the real sources'
  '';
})
```

### Solution 2: check whether `CRANE_BUILD_DEPS_ONLY` env var is set

> Note that with this approach, changing the build hook _will rebuild all
> dependencies_, so consider the first solution above if possible.

```nix
craneLib.buildPackage {
  src = ./.;

  postConfigure = ''
    # NB: use ''${var} to escape the ${...} so that Nix does not interpet it as
    # an evaluation variable (since CRANE_BUILD_DEPS_ONLY is a shell variable)
    if [ -n "''${CRANE_BUILD_DEPS_ONLY:-}"]; then
      echo 'I am a hook which must only run during buildDepsOnly'
    fi
  '';

  preBuild = ''
    # NB: use ''${var} to escape the ${...} so that Nix does not interpet it as
    # an evaluation variable (since CRANE_BUILD_DEPS_ONLY is a shell variable)
    if [ -z "''${CRANE_BUILD_DEPS_ONLY:-}"]; then
      echo 'I am a hook which must run with the real sources'
    fi
  '';
}
```
