[Trunk](https://trunkrs.dev) is a tool that allow you to build web apps using Rust and webassembly, including compiling scss, and distributing other assets.
It can be used in conjunction with any of Rust's web frameworks for the development of full stack web applications.

In this example we have a workspace with three members:

* client: a Yew application compiled using Trunk
* server: a Axum server built using Cargo
* shared: a library that contains types to be imported in both the client and server

Quick-start a Trunk+Server project with

```sh
nix flake init -t github:ipetkov/crane#trunk-workspace
```

Alternatively, copy and paste the following `flake.nix` and modify it to build your workspace's packages:

```nix
{{#include ../../examples/trunk-workspace/flake.nix}}
```
