{ pkgs, llmAgentPackages, ... }:

# Sandboxed opencode using bubblewrap
#
# --unshare-all        isolates all namespaces (pid, ipc, uts, mount, user, cgroup)
# --share-net          re-enables network so opencode can reach AI APIs
# --new-session        prevents terminal injection attacks (TIOCSTI), but breaks terminal resize (SIGWINCH)
# Pass --secure to enable --new-session; omit for normal use with working resize
# --uid/--gid          preserves real uid/gid inside the user namespace (default would be root)
# --proc/--dev         minimal proc and dev filesystems required for programs to run
# --tmpfs /tmp         fresh tmp to avoid leaks from other processes
# --ro-bind /nix       actual binaries live here
# --symlink /bin/sh    opencode and its tools can spawn shell commands;
#                      target is already inside the sandbox, this just names it
# --ro-bind /etc       ssl certs, dns, tls etc (--tmpfs /etc/ssh to remove SSH config with readonly perms)
# --ro-bind /run/current-system  symlinks to /nix/store binaries (needed for PATH)
# --tmpfs $HOME        blank home - hides ssh keys, dotfiles, shell history, credentials
# --bind ~/.config/opencode           punch through opencode config and secrets for persistence
# --bind ~/.local/share/opencode      punch through opencode data (auth.json, db) for persistence
# --ro-bind ~/.config/git/config  git needs user identity
# --ro-bind ~/.config/git/ignore  global gitignore
# --ro-bind ~/.ssh/known_hosts    host key verification for SSH git remotes
# --bind $SSH_AUTH_SOCK                ssh agent socket (set by UWSM) for git push/pull over ssh urls
# --bind $PWD          read-write access to the project directory
pkgs.writeShellScriptBin "opencode-sandbox" ''
  mkdir -p "$HOME/.config/opencode"
  mkdir -p "$HOME/.local/share/opencode"

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
    --bind "$HOME/.config/opencode" "$HOME/.config/opencode" \
    --bind "$HOME/.local/share/opencode" "$HOME/.local/share/opencode" \
    --ro-bind-try "$HOME/.config/git/config" "$HOME/.config/git/config" \
    --ro-bind-try "$HOME/.config/git/ignore" "$HOME/.config/git/ignore" \
    --ro-bind-try "$HOME/.ssh/known_hosts" "$HOME/.ssh/known_hosts" \
    --bind-try "$SSH_AUTH_SOCK" "$SSH_AUTH_SOCK" \
    --bind "$PWD" "$PWD" --chdir "$PWD" \
    -- ${llmAgentPackages.opencode}/bin/opencode "$@"
''
