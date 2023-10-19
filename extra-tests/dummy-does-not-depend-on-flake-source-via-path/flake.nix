{
  inputs = {
    crane.url = "github:ipetkov/crane";
    nixpkgs.follows = "crane/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { flake-utils, crane, ... }: flake-utils.lib.eachDefaultSystem
    (system: {
      packages.dummy = crane.lib.${system}.mkDummySrc {
        src = ./.;
      };
    });
}
