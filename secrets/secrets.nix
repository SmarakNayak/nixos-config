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
  "antec-admin-ssh-key.age".publicKeys = [ master ];
  "deepseek-api-key.age".publicKeys = [ master ];
  "zai-api-key.age".publicKeys = [ master ];
  "smarak-agent-github-app.age".publicKeys = [ master ];
  "telegram-bot-token.age".publicKeys = [ master ];
  "telegram-chat-id.age".publicKeys = [ master ];
  "antec-pc-wifi.env.age".publicKeys = [ master ];
  # Hermes mail/calendar OAuth (see hosts/antec-pc/hermes-mail.nix). Google only:
  # one shared client secret + a static refresh token per account. Microsoft's
  # token rotates (90-day per-token window) so it is NOT in Agenix — it lives in
  # a mutable host file (/var/lib/hermes/oauth/ms-hotmail.refresh).
  "google-oauth-client-secret.age".publicKeys = [ master ];
  "google-refresh-casual.age".publicKeys = [ master ];
  "google-refresh-proper.age".publicKeys = [ master ];
  "google-refresh-work.age".publicKeys = [ master ];
}
