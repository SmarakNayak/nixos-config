# Create the restricted runtime material consumed by Hermes command containers.
#
# Inputs supplied by earlier reconciliation phases:
#   agent_token      Initial token if the Hermes agent was just created; empty
#                    when an existing token should be validated or rotated.
#   agent_vault_url  Agent Vault management API base URL.
#   agent_vault_system_ca  Nixpkgs' public certificate authority bundle.
#   session_token    Short-lived owner-session token used only if rotation is
#                    required; it is never written to the Hermes handoff.
#   vault_name       Vault assigned to the Hermes proxy identity.
#   agent_name       Agent identity whose token may be rotated.
#
# Outputs written atomically to the Hermes workspace:
#   .agent-vault/ca.pem  Agent Vault MITM certificate authority.
#   .agent-vault/ca-bundle.pem  Public and Agent Vault certificate authorities.
#   .agent-vault/env     Restricted agent token, proxy URL, and CA environment.
#
# The function may update agent_token with a validated existing token or a newly
# rotated token before writing the handoff file.
agent_vault_write_hermes_handoff() {
  client_env=/var/lib/hermes/workspace/.agent-vault/env
  if [ -z "$agent_token" ] && [ -r "$client_env" ]; then
    current_token="$(sed -n 's/^AGENT_VAULT_TOKEN=//p' "$client_env")"
    if [ -n "$current_token" ] && curl -fsS \
      -H "Authorization: Bearer $current_token" -H "X-Vault: $vault_name" \
      "$agent_vault_url/discover" >/dev/null 2>&1; then
      agent_token="$current_token"
    fi
  fi
  if [ -z "$agent_token" ]; then
    agent_token="$(curl -fsS -X POST \
      -H "Authorization: Bearer $session_token" \
      -H 'Content-Type: application/json' -d '{}' \
      "$agent_vault_url/v1/agents/$agent_name/rotate" | jq -er '.av_agent_token')"
  fi

  ca_tmp="$(mktemp /var/lib/hermes/workspace/.agent-vault/.ca.pem.XXXXXX)"
  curl -fsS "$agent_vault_url/v1/mitm/ca.pem" > "$ca_tmp"
  chmod 0640 "$ca_tmp"
  mv "$ca_tmp" /var/lib/hermes/workspace/.agent-vault/ca.pem

  ca_bundle_tmp="$(mktemp /var/lib/hermes/workspace/.agent-vault/.ca-bundle.pem.XXXXXX)"
  cat "$agent_vault_system_ca" \
    /var/lib/hermes/workspace/.agent-vault/ca.pem > "$ca_bundle_tmp"
  chmod 0640 "$ca_bundle_tmp"
  mv "$ca_bundle_tmp" /var/lib/hermes/workspace/.agent-vault/ca-bundle.pem

  env_tmp="$(mktemp /var/lib/hermes/workspace/.agent-vault/.env.XXXXXX)"
  chmod 0640 "$env_tmp"
  proxy_url="http://$agent_token:$vault_name@host.containers.internal:14322"
  printf 'AGENT_VAULT_ADDR=http://host.containers.internal:14321\n' > "$env_tmp"
  printf 'AGENT_VAULT_VAULT=%s\n' "$vault_name" >> "$env_tmp"
  printf 'AGENT_VAULT_TOKEN=%s\n' "$agent_token" >> "$env_tmp"
  printf 'HTTPS_PROXY=%s\n' "$proxy_url" >> "$env_tmp"
  printf 'HTTP_PROXY=%s\n' "$proxy_url" >> "$env_tmp"
  printf 'NO_PROXY=localhost,127.0.0.1,host.containers.internal\n' >> "$env_tmp"
  printf 'NODE_USE_ENV_PROXY=1\n' >> "$env_tmp"
  printf 'OPENCLAW_PROXY_URL=%s\n' "$proxy_url" >> "$env_tmp"
  # Node, Requests/certifi, and Deno do not consistently use the OS trust
  # store mounted by agent-vault.nix, so retain only their runtime-specific
  # compatibility hooks.
  printf 'NODE_EXTRA_CA_CERTS=/workspace/.agent-vault/ca.pem\n' >> "$env_tmp"
  printf 'REQUESTS_CA_BUNDLE=/workspace/.agent-vault/ca-bundle.pem\n' >> "$env_tmp"
  printf 'DENO_CERT=/workspace/.agent-vault/ca-bundle.pem\n' >> "$env_tmp"
  mv "$env_tmp" "$client_env"
}
