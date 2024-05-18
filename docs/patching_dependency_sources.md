## Patching sources of dependency crates

Sometimes it is useful to patch the sources of dependency crates without needing
to wait for an upstream release to include a necessary change, or without
needing to use a custom git fork.

The `vendorCargoDeps`, `vendorCargoRegistries`, `vendorGitDeps`, and
`vendorMultipleCargoDeps` APIs support arbitrary overrides (i.e. patching) at
the individual crate/repo level when vendoring sources. Checkout their
respective API documentation for more details, but below is a short quick start
example:

```nix
let
  baseArgs = {
    src = craneLib.cleanCargoSource ./.;
  };

  isNumCpusRepo = p: lib.hasPrefix
      "git+https://github.com/seanmonstar/num_cpus.git"
      p.source;
  isTag1_13_1 = p: lib.hasInfix
      "tag=v1.13.1"
      p.source;

  cargoVendorDir = craneLib.vendorCargoDeps (baseArgs // {
    # Use this function to override crates coming from git dependencies
    overrideVendorGitCheckout = ps: drv:
      # For example, patch a specific repository and tag, in this case num_cpus-1.13.1
      if lib.any (p: (isNumCpusRepo p) && (isTag1_13_1 p)) ps then
        drv.overrideAttrs (_old: {
          # Specifying an arbitrary patch to apply
          patches = [
            ./0001-patch-num-cpus.patch
          ];

          # Similarly we can also run additional hooks to make changes
          postPatch = ''
            echo running some arbitrary command to make modifications
          '';
        })
      else
        # Nothing to change, leave the derivations as is
        drv;

    # Use this function to override crates coming from any registry checkout
    overrideVendorCargoPackage = p: drv:
      # For example, patch a specific crate, in this case byteorder-1.5.0
      if p.name == "byteorder" && p.version == "1.5.0" then
        drv.overrideAttrs (_old: {
          # Specifying an arbitrary patch to apply
          patches = [
            ./0001-patch-byteorder.patch
          ];

          # Similarly we can also run additional hooks to make changes
          postPatch = ''
            echo running some arbitrary command to make modifications
          '';
        })
      else
        # Nothing to change, leave the derivations as is
        drv;
  });

  commonArgs = baseArgs // {
    inherit cargoVendorDir;
  };
in
craneLib.buildPackage commonArgs
```
