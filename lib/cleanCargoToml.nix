{
  lib,
}:

let
  pathsToKeepDefaultPerTarget = target: [
    # https://doc.rust-lang.org/cargo/reference/cargo-targets.html#configuring-a-target
    [target "edition"]    # Influences cargo behavior
    [target "path"]       # maintain project structure
    [target "name"]       # let cargo manage targets/collisions/etc.
    [target "crate-type"] # some tools may try to inspect crate types (e.g. wasm-pack), retain the
                          # definition to honor the project structure
    [target "proc-macro"] # If we have a proc-macro dependency in the workspace, rustc may try to
                          # compile `proc-macro2` for the target system
    [target "harness"]    # Controls how tests are compiled and run, which might have implications
                          # on additional scripts which try to run the tests during buildDepsOnly
  ];

  # https://doc.rust-lang.org/cargo/reference/manifest.html
  pathsToKeepDefault = [
    ["build-dependencies"] # We want to build and cache these
    ["cargo-features"]     # Just in case some special depencency-related features are needed
    ["dependencies"]       # We want build and cache these
    ["dev-dependencies"]   # We want to build and cache these
    ["features"]           # Keep this as is, some deps may be compiled with different feature combinations
    ["patch"]              # Configures sources as the project wants
    ["profile"]            # This could influence how dependencies are built/optimized
    ["replace"]            # (deprecated) configures sources as the project wants
    ["target"]             # We want to build and cache these
    # https://doc.rust-lang.org/cargo/reference/manifest.html#the-package-section
    ["package" "edition"]    # Influences cargo behavior
    ["package" "name"]       # Required
    ["package" "resolver"]   # Influences cargo behavior when edition != 2021
    ["package" "version"]    # Required
    ["package" "workspace"]  # Keep project structure as is
    # https://doc.rust-lang.org/cargo/reference/workspaces.html
    ["workspace" "default-members"] # Keep project structure as is
    ["workspace" "exclude"]         # Keep project structure as is
    ["workspace" "dependencies"]    # We want to build and cache these
    ["workspace" "members"]         # Keep project structure as is
    ["workspace" "package"]
    ["workspace" "resolver"]        # Influences cargo behavior
  ]
  ++ (pathsToKeepDefaultPerTarget "lib")
  ++ (pathsToKeepDefaultPerTarget "bin")
  ++ (pathsToKeepDefaultPerTarget "example")
  ++ (pathsToKeepDefaultPerTarget "test")
  ++ (pathsToKeepDefaultPerTarget "bench");

  # like lib.recursiveUpdate, but merges lists by merging elements by index
  # instead of replacing the whole list
  deepMerge =
    lhs: rhs:
    if builtins.isAttrs lhs && builtins.isAttrs rhs then
      builtins.listToAttrs (
        builtins.map (name: {
          inherit name;
          value =
            if builtins.hasAttr name lhs then
              if builtins.hasAttr name rhs then deepMerge lhs.${name} rhs.${name} else lhs.${name}
            else
              rhs.${name};
        }) (builtins.attrNames (lhs // rhs))
      )
    else if builtins.isList lhs && builtins.isList rhs then
      let
        lenL = builtins.length lhs;
        lenR = builtins.length rhs;
        maxLen = if lenL > lenR then lenL else lenR;
      in
      builtins.genList (
        i:
        if i < lenL && i < lenR then
          deepMerge (builtins.elemAt lhs i) (builtins.elemAt rhs i)
        else if i < lenL then
          builtins.elemAt lhs i
        else
          builtins.elemAt rhs i
      ) maxLen
    else
      rhs;

  # extracts the value at attrPath from set / list, preserving the structure along attrPath
  # treats lists by mapping over their elements
  # returns an empty set if attrPath does not exist in set
  extractPath =
    attrPath: set:
    let
      lenAttrPath = builtins.length attrPath;
      extractPath' =
        n: s:
        (
          if n == lenAttrPath then
            lib.setAttrByPath attrPath s
          else
            (
              if builtins.isList s then
                let
                  currentPath = lib.sublist 0 n attrPath;
                  nextPath = lib.sublist n (lenAttrPath - n) attrPath;
                in
                lib.setAttrByPath currentPath (builtins.map (x: extractPath nextPath x) s)
              else
                (
                  let
                    attr = builtins.elemAt attrPath n;
                  in
                  if s ? ${attr} then extractPath' (n + 1) s.${attr} else { }
                )
            )
        );
    in
    extractPath' 0 set;

  cleanCargoToml =
    input: pathsModifier:
    builtins.foldl' (acc: path: deepMerge acc (extractPath path input)) { } (
      pathsModifier pathsToKeepDefault
    );
in
{
  cargoToml ? throw "either cargoToml or cargoTomlContents must be specified",
  cargoTomlContents ? builtins.readFile cargoToml,
  pathsModifier ? (x: x),
}:
cleanCargoToml (builtins.fromTOML cargoTomlContents) pathsModifier
