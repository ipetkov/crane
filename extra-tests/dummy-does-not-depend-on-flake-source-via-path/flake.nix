{
  inputs = {
    crane.url = "github:ipetkov/crane";
    nixpkgs.follows = "crane/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, crane, ... }: flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      craneLib = crane.mkLib pkgs;
    in
    {
      packages.dummy = craneLib.mkDummySrc {
        src = ./.;
      };
    });
}
