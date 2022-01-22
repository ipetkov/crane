# Crane

A [Nix](https://nixos.org/) library for building [cargo](https://doc.rust-lang.org/cargo/) projects.

* **No messing with hashes**: a Cargo.lock file is all you need
* **Incremental**: never build a dependency twice with easy artifact caching
* **Composable**: split builds and tests into granular steps. Gate CI without
  burdening downstream consumers building from source.

## Features

Examples can be found [here](./examples). Detailed [API docs] are available, but
at a glance, the following are supported:
* Automatic vendoring of dependencies in a way that works with Nix
  - Private registry and git dependency support coming soon!
* Reusing dependency artifacts after only building them once
* [clippy](https://github.com/rust-lang/rust-clippy) checks
* [rustfmt](https://github.com/rust-lang/rustfmt) checks
* [cargo-tarpaulin](https://github.com/xd009642/tarpaulin) for code coverage

## Getting Started

The easiest way to get started is to initialize a flake from a template:

```sh
# Start with a comprehensive suite of tests
nix flake init -t github:ipetkov/crane#quick-start

# Or if you want something simpler
nix flake init -t github:ipetkov/crane#quick-start-simple

# If you need a custom rust toolchain (e.g. to build WASM targets):
nix flake init -t github:ipetkov/crane#custom-toolchain
```

For an even more lean, no frills set up, create a `flake.nix` file with the
following contents at the root of your cargo workspace:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    crane.url = "github:ipetkov/crane";
    crane.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, crane, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system: {
      defaultPackage = crane.lib.${system}.buildPackage {
        src = ./.;
      };
    });
}
```

## Philosophy

Crane is designed around the idea of composing cargo invocations such that they
can take advantage of the artifacts generated in previous invocations. This
allows for both flexible configurations and great caching (à la Cachix) in CI
and local development builds.

Here's how it works at a high level: when a cargo workspace is built its source
is first transformed such that only the dependencies listed by the `Cargo.toml`
and `Cargo.lock` files are built, and none of the crate's real source is
included. This allows cargo to build all dependency crates and prevents Nix from
invalidating the derivation whenever the source files are updated. Then, a
second derivation is built, this time using the real source files, which also
imports the cargo artifacts generated in the first step.

Let's take a look at two examples at how very similar configurations can give us
very different behavior!

### Example One

Suppose we are developing a crate and want to run our CI assurance checks
via `nix flake check`. Perhaps we want the CI gate to be very strict and block
any changes which raise warnings when run with `cargo clippy`. Oh, and we want
to enforce some code coverage too!

Except we do not want to push our strict guidelines on any downstream consumers
who may want to build our crate. Suppose they need to build the crate with a
different compiler version (for one reason or another) which comes with a new lint
whose warnings we have not yet addressed. We don't want to make their life
harder, so we want to make sure we do not run `cargo clippy` as part of the
crate's actual derivation, but at the same time, we don't want to have to
rebuild dependencies from scratch.

Here's how we can set up our flake to achieve our goals:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    crane.url = "github:ipetkov/crane";
    crane.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, crane, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        craneLib = crane.lib.${system};
        src = ./.;

        # Build *just* the cargo dependencies, so we can reuse
        # all of that work (e.g. via cachix) when running in CI
        cargoArtifacts = craneLib.buildDepsOnly {
          inherit src;
        };

        # Run clippy (and deny all warnings) on the crate source,
        # resuing the dependency artifacts (e.g. from build scripts or
        # proc-macros) from above.
        #
        # Note that this is done as a separate derivation so it
        # does not impact building just the crate by itself.
        my-crate-clippy = craneLib.cargoClippy {
          inherit cargoArtifacts src;
          cargoClippyExtraArgs = "-- --deny warnings";
        };

        # Build the actual crate itself, reusing the dependency
        # artifacts from above.
        my-crate = craneLib.buildPackage {
          inherit cargoArtifacts src;
        };

        # Also run the crate tests under cargo-tarpaulin so that we can keep
        # track of code coverage
        my-crate-coverage = craneLib.cargoTarpaulin {
          inherit cargoArtifacts src;
        };
      in
      {
        defaultPackage = my-crate;
        checks = {
         inherit
           # Build the crate as part of `nix flake check` for convenience
           my-crate
           my-crate-clippy
           my-crate-coverage;
        };
      });
}
```

When we run `nix flake check` the following will happen:
1. The sources for any dependency crates will be fetched
1. They will be built without our crate's code and the artifacts propagated
1. Our crate, the clippy checks, and code coverage collection will be built,
   each reusing the same set of artifacts from the initial source-free build. If
   enough cores are available to Nix it may build all three derivations
   completely in parallel, or schedule them in some arbitrary order.

Splitting up our builds like this also gives us the benefit of granular control
over what is rebuilt. Suppose we change our mind and decide to adjust the clippy
flags (e.g. to allow certain lints or forbid others). Doing so will _only_
rebuild the clippy derivation, without having to rebuild and rerun any of our
other tests!

### Example Two

Let's take an alternative approach to the example above. Suppose instead that we
care more about not wasting any resources building certain tests (even if they
would succeed!) if another particular test fails. Perhaps binary substitutes are
readily available so that we do not mind if anyone building from source is bound
by our rules, and we can be sure that all tests have passed as part of the
build.

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    crane.url = "github:ipetkov/crane";
    crane.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, crane, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        craneLib = crane.lib.${system};
        src = ./.;

        # Build *just* the cargo dependencies, so we can reuse
        # all of that work (e.g. via cachix) when running in CI
        cargoArtifacts = craneLib.buildDepsOnly {
          inherit src;
        };

        # First, run clippy (and deny all warnings) on the crate source.
        my-crate-clippy = craneLib.cargoClippy {
          inherit cargoArtifacts src;
          cargoClippyExtraArgs = "-- --deny warnings";
        };

        # Next, we want to run the tests and collect code-coverage, _but only if
        # the clippy checks pass_ so we do not waste any extra cycles.
        my-crate-coverage = craneLib.cargoTarpaulin {
          inherit src;
          cargoArtifacts = my-crate-clippy;
        };

        # Build the actual crate itself, _but only if the previous tests pass_.
        my-crate = craneLib.buildPackage {
          cargoArtifacts = my-crate-coverage;
          inherit src;
        };
      in
      {
        defaultPackage = my-crate;
        checks = {
         inherit
           # Build the crate as part of `nix flake check` for convenience
           my-crate
           my-crate-coverage;
        };
      });
}
```

When we run `nix flake check` the following will happen:
1. The sources for any dependency crates will be fetched
1. They will be built without our crate's code and the artifacts propagated
1. Next the clippy checks will run, reusing the dependency artifacts above.
1. Next the code coverage tests will run, reusing the artifacts from the clippy
   run
1. Finally the actual crate itself is built

In this case we lose the ability to build derivations independently, but we gain
the ability to enforce a strict build order. However, we can easily change our
mind, which would be much more difficult if we had written everything as one
giant derivation.

## FAQs

### I want to use a custom version of nixpkgs or another specific system

The crane library can be instantiated with a specific version of nixpkgs as
follows. For more information, see the [API docs] for `mkLib`.

```nix
crane.mkLib (import nixpkgs { system = "armv7l-linux"; })
```

### I want to override a particular package used by the crane library

Specific inputs can be overridden for the entire library via the
`overrideScope'` API as follows. For more information, see the [API docs] for
`mkLib` or checkout the [custom-toolchain] example.

```nix
crane.lib.${system}.overrideScope' (final: prev: {
  cargo = myCustomCargoVersion;
})
```

### My custom rust flags are getting ignored

If you are using a `build.rustflags` definition in `.cargo/config.toml`,
consider turning off source prefix remapping by adding
`doRemapSourcePathPrefix = false;` in your derivation.

See the [API docs] for `remapSourcePathPrefixHook` for more information.

### Nix is complaining about IFD (import from derivation)

If a derivation's `pname` and `version` attributes are not explicitly set,
crane will inspect the project's `Cargo.toml` file to set them as a convenience
to avoid duplicating that information by hand. This works well when the source
is a local path, but can cause issues if the source is being fetched remotely,
or flakes are not being used (since flakes have IFD enabled on by default).

One easy workaround for this issue (besides enabling the
`allow-import-from-derivation` option in Nix) is to explicitly set
`{ pname = "..."; version = "..."; }` in the derivation.

You'll know you've run into this issue if you see error messages along the lines
of:
* `cannot build '/nix/store/...-source.drv' during evaluation because the option 'allow-import-from-derivation' is disabled`
* `a 'aarch64-darwin' with features {} is required to build '/nix/store/...', but I am a 'x86_64-linux' with features {}`

## License

This project is licensed under the [MIT license].

### Contribution

Unless you explicitly state otherwise, any contribution intentionally submitted
for inclusion by you, shall be licensed as MIT, without any additional terms or
conditions.

[API docs]: ./docs/API.md
[custom-toolchain]: ./examples/custom-toolchain/flake.nix
[MIT license]: ./LICENSE
