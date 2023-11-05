{
  inputs = {
    crane.url = "github:ipetkov/crane";
    nixpkgs.follows = "crane/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { flake-utils, crane, ... }: flake-utils.lib.eachDefaultSystem (system:
    let
      craneLib = crane.lib.${system};
    in
    {
      # https://github.com/ipetkov/crane/issues/446
      packages.default = craneLib.buildPackage {
        src = craneLib.cleanCargoSource (craneLib.path ../../checks/simple);
      };
    });
}
