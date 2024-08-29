## Local Development

[Nix shells (or development
shells)](https://nix.dev/tutorials/ad-hoc-developer-environments) are extremely
powerful when it comes to locally developing with the exact same dependencies
used when building packages.

To get started, declare a default `devShell` in `flake.nix` using
[`craneLib.devShell`](API.md#cranelibdevshell) and run `nix develop` in the
project directory. Then, you can use something like
[`direnv`](https://direnv.net) or
[`nix-direnv`](https://github.com/nix-community/nix-direnv) to automatically
enter and exit a development shell when you enter or exit the project
directory!

Sample `flake.nix`:
```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    crane.url = "github:ipetkov/crane";

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, crane, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        craneLib = crane.mkLib pkgs;

        my-crate = craneLib.buildPackage {
          src = craneLib.cleanCargoSource ./.;

          buildInputs = [
            # Add additional build inputs here
          ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
            # Additional darwin specific inputs can be set here
            pkgs.libiconv
          ];

          # Additional environment variables can be set directly
          # MY_CUSTOM_VAR = "some value";
        };
      in
      {
        packages.default = my-crate;

        devShells.default = craneLib.devShell {
          # Additional dev-shell environment variables can be set directly
          MY_CUSTOM_DEV_URL = "http://localhost:3000";

          # Automatically inherit any build inputs from `my-crate`
          inputsFrom = [ my-crate ];

          # Extra inputs (only used for interactive development)
          # can be added here; cargo and rustc are provided by default.
          packages = [
            pkgs.cargo-audit
            pkgs.cargo-watch
          ];
        };
      });
}
```

Then, after integrating direnv into your shell:
```sh
echo "use flake" > .envrc
direnv allow
```
