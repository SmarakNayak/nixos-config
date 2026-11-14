{ pkgs, ... }:

# Sandboxed Claude Code using bubblewrap
#
# --unshare-all        isolates all namespaces (pid, ipc, uts, mount, user, cgroup)
# --share-net          re-enables network so Claude can reach the Anthropic API
# --new-session        prevents terminal injection attacks (TIOCSTI), but breaks terminal resize (SIGWINCH)
# Pass --secure to enable --new-session; omit for normal use with working resize
# --uid/--gid          preserves real uid/gid inside the user namespace (default would be root)
# --proc/--dev         minimal proc and dev filesystems required for programs to run
# --tmpfs /tmp         fresh tmp to avoid leaks from other processes
# --ro-bind /nix       actual binaries live here
# --symlink /bin/sh    claude spawns statusline/hooks via posix_spawn('/bin/sh');
#                      target is already inside the sandbox, this just names it
# --ro-bind /etc       ssl certs, dns, tls etc (--tmpfs /etc/ssh to remove SSH config with readonly perms)
# --ro-bind /run/current-system  symlinks to /nix/store binaries (needed for PATH)
# --tmpfs $HOME        blank home - hides ssh keys, dotfiles, shell history, credentials
# --bind ~/.claude(s)     punch through claude state and config for persistence
# --ro-bind ~/.config/git/config  git needs user identity
# --ro-bind ~/.config/git/ignore  global gitignore (e.g. .claude/settings.local.json)
# --ro-bind ~/.ssh/known_hosts    host key verification for SSH git remotes
# --bind $SSH_AUTH_SOCK                ssh agent socket (set by UWSM) for git push/pull over ssh urls
# --bind $PWD          read-write access to the project directory
let
  # Sandbox-only settings: bypass-mode acceptance is only read from ~/.claude/settings.json.
  # Bound over the resolved store file since bwrap can't mount onto a symlink.
  sandboxSettings = pkgs.writeText "claude-sandbox-settings.json" (builtins.toJSON (
    builtins.fromJSON (builtins.readFile ../dotfiles/claude/settings.json)
    // { skipDangerousModePermissionPrompt = true; }
  ));
in
pkgs.writeShellScriptBin "claude-sandbox" ''
  mkdir -p "$HOME/.claude"
  touch "$HOME/.claude.json"

  NEW_SESSION=""
  if [ "$1" = "--secure" ]; then
    NEW_SESSION="--new-session"
    shift
  fi

  exec ${pkgs.bubblewrap}/bin/bwrap \
    --unshare-all --share-net $NEW_SESSION \
    --uid "$(id -u)" --gid "$(id -g)" \
    --proc /proc --dev /dev --tmpfs /tmp \
    --ro-bind /nix /nix \
    --symlink /run/current-system/sw/bin/sh /bin/sh \
    --ro-bind /etc /etc --tmpfs /etc/ssh \
    --ro-bind-try /run/current-system /run/current-system \
    --tmpfs "$HOME" \
    --bind "$HOME/.claude" "$HOME/.claude" --bind "$HOME/.claude.json" "$HOME/.claude.json" \
    --ro-bind ${sandboxSettings} "$(readlink -f "$HOME/.claude/settings.json")" \
    --ro-bind-try "$HOME/.config/git/config" "$HOME/.config/git/config" \
    --ro-bind-try "$HOME/.config/git/ignore" "$HOME/.config/git/ignore" \
    --ro-bind-try "$HOME/.ssh/known_hosts" "$HOME/.ssh/known_hosts" \
    --bind-try "$SSH_AUTH_SOCK" "$SSH_AUTH_SOCK" \
    --bind "$PWD" "$PWD" --chdir "$PWD" \
    -- ${pkgs.claude-code}/bin/claude --dangerously-skip-permissions "$@"
''
