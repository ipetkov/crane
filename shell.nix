let
  lock = builtins.fromJSON (builtins.readFile ./test/flake.lock);
  locked = lock.nodes.flake-compat.locked;
  compat =
    if locked.type == "tarball" then
      fetchTarball {
        url = locked.url;
        sha256 = locked.narHash;
      }
    else if locked.type == "github" then
      fetchTarball {
        url = "https://github.com/${locked.owner}/${locked.repo}/archive/${locked.rev}.tar.gz";
        sha256 = locked.narHash;
      }
    else
      throw "Unsupported locked flake input type: ${locked.type}";

  flake = import compat {
    src = builtins.path {
      path = ./.;
      name = "crane";
    };
  };
in
flake.shellNix
