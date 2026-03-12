{ pkgs, ... }:

pkgs.writeShellScriptBin "claude-distro" ''
  export PATH="${pkgs.podman}/bin:$PATH"
  CONTAINER="ubuntu"
  if ! ${pkgs.distrobox}/bin/distrobox list | grep -q "| $CONTAINER"; then
    echo "Creating $CONTAINER distrobox (first run)..."
    ${pkgs.distrobox}/bin/distrobox create --name "$CONTAINER" --image ubuntu:latest --yes
  fi

  # Check if claude-code is installed in the container
  if ! ${pkgs.distrobox}/bin/distrobox enter "$CONTAINER" -- test -f ~/.local/bin/claude; then
    echo "Installing claude-code..."
    ${pkgs.distrobox}/bin/distrobox enter "$CONTAINER" -- bash -c 'curl -fsSL https://claude.ai/install.sh | bash'
  fi

  exec ${pkgs.distrobox}/bin/distrobox enter "$CONTAINER" -- ~/.local/bin/claude "$@"
''
