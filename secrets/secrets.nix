let
  # Your master key public part
  master = "age1amd42k828cgyv6kk8pltkknpxklyauz8pnzde73spp8l2w2n5qgsgdsjlu";
in {
  # To add a new secret:
  # 1. Add an entry below: "my-secret.age".publicKeys = [ master ];
  # 2. Run from this directory: nix run github:ryantm/agenix -- -e my-secret.age
  # 3. Type the secret value in the editor, save and quit
  # 4. Declare it in home.nix under age.secrets and reference the .path
  "ssh-key.age".publicKeys = [ master ];
  "ssh-key-hetzner.age".publicKeys = [ master ];
  "deepseek-api-key.age".publicKeys = [ master ];
}
