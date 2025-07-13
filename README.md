# nixos-config
Config files for my nixos setup.
List of imperative steps taken:
- partitioning (look into disko.nix)
- ssh-keygen -t ed25519 -C "miltu.s.nayak@gmail.com"
- add key to github
- git clone nixos-config
- sudo mv /etc/nixos /etc/nixos.bak     # Backup the original configuration
- sudo ln -s ~/nixos-config /etc/nixos  # Symlink config to default nix config location
