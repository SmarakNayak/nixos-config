{ pkgs, ... }:

# Sandboxed Claude Code using bubblewrap
#
# --unshare-all        isolates all namespaces (pid, ipc, uts, mount, user, cgroup)
# --share-net          re-enables network so Claude can reach the Anthropic API
# --new-session        prevents terminal injection attacks (TIOCSTI)
# --uid/--gid          preserves real uid/gid inside the user namespace (default would be root)
# --proc/--dev         minimal proc and dev filesystems required for programs to run
# --tmpfs /tmp         fresh tmp to avoid leaks from other processes
# --ro-bind /nix       actual binaries live here
# --ro-bind /etc       ssl certs, dns, tls etc (--tmpfs /etc/ssh to remove SSH config with readonly perms)
# --ro-bind /run/current-system  symlinks to /nix/store binaries (needed for PATH)
# --tmpfs $HOME        blank home - hides ssh keys, dotfiles, shell history, credentials
# --bind ~/.claude(s)     punch through claude state and config for persistence
# --ro-bind ~/.config/git/config  git needs user identity
# --bind $SSH_AUTH_SOCK                ssh agent socket (set by UWSM) for git push/pull over ssh urls
# --bind $PWD          read-write access to the project directory
pkgs.writeShellScriptBin "claude-sandbox" ''
  mkdir -p "$HOME/.claude"
  touch "$HOME/.claude.json"

  exec ${pkgs.bubblewrap}/bin/bwrap \
    --unshare-all --share-net --new-session \
    --uid "$(id -u)" --gid "$(id -g)" \
    --proc /proc --dev /dev --tmpfs /tmp \
    --ro-bind /nix /nix \
    --ro-bind /etc /etc --tmpfs /etc/ssh \
    --ro-bind-try /run/current-system /run/current-system \
    --tmpfs "$HOME" \
    --bind "$HOME/.claude" "$HOME/.claude" --bind "$HOME/.claude.json" "$HOME/.claude.json" \
    --ro-bind-try "$HOME/.config/git/config" "$HOME/.config/git/config" \
    --bind-try "$SSH_AUTH_SOCK" "$SSH_AUTH_SOCK" \
    --bind "$PWD" "$PWD" --chdir "$PWD" \
    -- ${pkgs.claude-code}/bin/claude --dangerously-skip-permissions "$@"
''
