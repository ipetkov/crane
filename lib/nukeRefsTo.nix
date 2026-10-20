{
  lib,
  writeShellScript,
  ripgrep,
}:

writeShellScript "nuke-refs-to" ''
      set -euo pipefail
      hash="$1"
      path="$2"
      tmp_path="''${path}_nukedrefs"
      (${lib.getExe ripgrep} -a --passthru -N -U -r /nix/store/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee "$hash" "$path" || true) | head -c -1 > "$tmp_path"
      mv "$tmp_path" "$path"
''
