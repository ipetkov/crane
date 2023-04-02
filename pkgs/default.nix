{ pkgs, myLib }:

{
  book =
    let
      inherit (pkgs) lib;
      root = myLib.path ./..;
      rootPrefix = toString root;
      cleanedSrc = lib.cleanSourceWith {
        src = root;
        filter = path: _:
          let
            relativePath = lib.removePrefix rootPrefix path;
          in
          lib.any (prefix: lib.hasPrefix prefix relativePath) [
            "/docs" # Build the docs directory
            "/examples" # But also include examples as we cross-reference them
            "/README.md"
            "/CHANGELOG.md"
          ];
      };
    in
    pkgs.runCommand "crane-book" { } ''
      ${pkgs.mdbook}/bin/mdbook build --dest-dir $out ${cleanedSrc}/docs
    '';

  crane-utils = myLib.callPackage ./crane-utils { };
}
