In addition to Unit and Integration tests, you can also write tests that
interact with your application as a real user would.
That technique is called End to End(E2E) testing.

In this example we have a workspace with two members:

* server: a web server that uses Axum for HTTP and Sqlx
  connect to an instance of PostgreSQL
* e2e: a end-to-end test "script" that drives
  Firefox into interacting with the sever

Quick-start an E2E project in a fresh directory with:

```sh
nix flake init -t github:ipetkov/crane#end-to-end-testing
```

Alternatively, if you have an existing project already, copy and paste the
following `flake.nix` and modify it to build your workspace's packages:

```nix
{{#include ../../examples/end-to-end-testing/flake.nix}}
```
