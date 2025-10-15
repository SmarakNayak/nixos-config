# nixos-config
Config files for my nixos setup.
List of imperative steps taken:
- partitioning (look into disko.nix)
- git clone nixos-config
- copy master.key into ~/.config/age/master.key. Make sure there is a newline at EOF
- sudo mv /etc/nixos /etc/nixos.bak # backup original config
- sudo ln -s ~/nixos-config /etc/nixos  # Symlink config to default nix config location
- sudo nixos-rebuild switch --flake ~/nixos-config
