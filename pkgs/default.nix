{ pkgs, myLib }:

{
  book =
    let
      inherit (pkgs) lib;
      cleanedSrc = lib.fileset.toSource {
        root = ./..;
        fileset = lib.fileset.unions [
          ./../docs
          ./../examples
          ./../README.md
          ./../CHANGELOG.md
        ];
      };
    in
    pkgs.runCommand "crane-book" { } ''
      ${pkgs.mdbook}/bin/mdbook build --dest-dir $out ${cleanedSrc}/docs
    '';

  crane-utils = myLib.callPackage ./crane-utils { };
}
