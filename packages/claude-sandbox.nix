{ pkgs, ... }:

pkgs.writeShellScriptBin "claude-sandbox" ''
  mkdir -p "$HOME/.claude"

  exec ${pkgs.bubblewrap}/bin/bwrap \
    --unshare-all --share-net --new-session \
    --uid "$(id -u)" --gid "$(id -g)" \
    --proc /proc --dev /dev --tmpfs /tmp \
    --ro-bind /nix /nix \
    --ro-bind /etc /etc \
    --ro-bind-try /run/current-system /run/current-system \
    --tmpfs "$HOME" \
    --bind "$HOME/.claude" "$HOME/.claude" \
    --bind "$PWD" "$PWD" --chdir "$PWD" \
    -- ${pkgs.claude-code}/bin/claude --dangerously-skip-permissions "$@"
''
