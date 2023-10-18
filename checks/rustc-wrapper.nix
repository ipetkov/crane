{ writeShellScript
}:

# A rustc wrapper which can conditionally refuse to re-build crates.
# Useful for testing that artifact caching isn't somehow broken
writeShellScript "rustc-wrapper" ''
  # Let through any cargo introspection calls
  if [[ -z "''${__CRANE_DENY_COMPILATION:-}" || "''${2:-}" == "-vV" || "''${4:-}" == "___" ]]; then
    exec "$@"
  fi

  >&2 echo "recompilation forbiden: $*"
  exit 1
''
