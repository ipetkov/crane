{
  inputs = {
    crane.url = "github:ipetkov/crane";
    nixpkgs.follows = "crane/nixpkgs";
    flake-utils.follows = "crane/flake-utils";
  };

  outputs = { self, flake-utils, crane, ... }: flake-utils.lib.eachDefaultSystem
    (system: {
      packages.dummy = crane.lib.${system}.mkDummySrc {
        src = self;
      };
    });
}
