{ internalCrateNameForCleanSource
, lib
}:

input:
let
  inputIsAttrs = lib.isAttrs input;
  name = input.name or (internalCrateNameForCleanSource (
    if inputIsAttrs then input.path else input
  ));

  pathArgs = if inputIsAttrs then input else { path = input; };
in
builtins.path ({ inherit name; } // pathArgs)
