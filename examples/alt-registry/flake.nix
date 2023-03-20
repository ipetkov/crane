{
  description = "Build a cargo project with alternative crate registries";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
    };
  };

  outputs = { self, nixpkgs, crane, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        craneLibOrig = crane.lib.${system};
        craneLib = craneLibOrig.appendCrateRegistries [
          # Automatically infer the download URL from the registry's index
          #
          # Note that this approach requires checking out the full index at the specified revision
          # and adding a copy to the Nix store.
          #
          # Also note that the specified git revision _does not need to track updates to the index
          # itself_ as long as the pinned revision contains the most recent version of the
          # registry's `config.json` file. In other words, this commit revision only needs to be
          # updated if the `config.json` file changes the download endpoint for this registry.
          (craneLibOrig.registryFromGitIndex {
            indexUrl = "https://github.com/Hirevo/alexandrie-index";
            rev = "90df25daf291d402d1ded8c32c23d5e1498c6725";
            fetchurlExtraArgs = {
              # Extra parameters which will be passed to the fetchurl invocation for each crate
            };
          })

          # As a more lightweight alternative, the `dl` endpoint of the registry's `config.json`
          # file can be copied here to avoid needing to copy the index to the Nix store.
          # (craneLibOrig.registryFromDownloadUrl {
          #   indexUrl = "https://github.com/Hirevo/alexandrie-index";
          #   dl = "https://crates.polomack.eu/api/v1/crates/{crate}/{version}/download";
          #   fetchurlExtraArgs = {
          #     # Extra parameters which will be passed to the fetchurl invocation for each crate
          #   };
          # })
        ];

        my-crate = craneLib.buildPackage {
          src = craneLib.cleanCargoSource (craneLib.path ./.);

          buildInputs = [
            # Add additional build inputs here
          ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
            # Additional darwin specific inputs can be set here
            pkgs.libiconv
            pkgs.darwin.apple_sdk.frameworks.Security
          ];

          # Specific to our example, but not always necessary in the general case.
          nativeBuildInputs = with pkgs; [
            pkg-config
            openssl
          ];
        };
      in
      {
        checks = {
          # Build the crate as part of `nix flake check` for convenience
          inherit my-crate;
        };

        packages.default = my-crate;

        apps.default = flake-utils.lib.mkApp {
          drv = my-crate;
        };

        devShells.default = pkgs.mkShell {
          inputsFrom = builtins.attrValues self.checks.${system};

          # Extra inputs can be added here
          nativeBuildInputs = with pkgs; [
            cargo
            rustc
          ];
        };
      });
}
