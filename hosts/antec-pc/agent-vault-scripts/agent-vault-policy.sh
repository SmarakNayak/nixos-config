# Reconcile the desired policy generated from agent-vault-policy.nix.
#
# Inputs supplied by the calling orchestration script:
#   agent_vault_policy  Path to the generated JSON policy in the Nix store.
#   agent_vault_url     Agent Vault management API base URL.
#   session_token       Short-lived token returned by POST /v1/auth/login. It
#                       authorizes these management API calls only and is never
#                       exposed to Hermes.
#   vault_name          Desired vault name read from the JSON policy.
#   agent_name          Desired agent name read from the JSON policy.
#
# Output:
#   agent_token         Initial token when this function creates the agent;
#                       empty when the agent already exists.
agent_vault_reconcile_policy() {
  # 1. Ensure the vault exists.
  vault_body="$(jq -c '{name:.vault.name}' "$agent_vault_policy")"
  create_code="$(curl -sS -o /dev/null -w '%{http_code}' -X POST \
    -H "Authorization: Bearer $session_token" \
    -H 'Content-Type: application/json' -d "$vault_body" \
    "$agent_vault_url/v1/vaults")"
  if [ "$create_code" != "201" ] && [ "$create_code" != "409" ]; then
    echo "agent-vault-config: vault creation failed (HTTP $create_code)" >&2
    exit 1
  fi

  # 2. Resolve and store declared credentials. Resolve only explicitly named
  # environment variables; secret values never enter the Nix store or policy.
  credential_body="$(jq -ce \
    '(.vault.credentials.environment // {}) as $refs
     | ($refs | to_entries
        | map(if env[.value] then {key:.key,value:env[.value]}
              else error("missing credential environment variable: " + .value)
              end)
        | from_entries) as $resolved
     | {vault:.vault.name,
        credentials:((.vault.credentials.static // {}) + $resolved)}' \
    "$agent_vault_policy")"
  agent_vault_request POST /v1/credentials "$credential_body"

  # 3. Atomically replace all service rules with the declared policy.
  services_body="$(jq -c '{services:.vault.services}' "$agent_vault_policy")"
  agent_vault_request PUT "/v1/vaults/$vault_name/services" "$services_body"

  # 4. Apply settings stored separately from service definitions.
  settings_body="$(jq -c '.vault.settings' "$agent_vault_policy")"
  agent_vault_request PATCH "/v1/vaults/$vault_name/settings" "$settings_body"

  # 5. Check whether the instance-level Hermes agent already exists.
  agent_code="$(curl -sS -o /dev/null -w '%{http_code}' \
    -H "Authorization: Bearer $session_token" \
    "$agent_vault_url/v1/agents/$agent_name")"
  agent_token=""
  if [ "$agent_code" = "404" ]; then
    # 6. When missing, create the agent and assign its instance role and vault
    # membership together. Agent Vault returns the initial token only once.
    agent_body="$(jq -c \
      '{name:.agent.name,role:.agent.role,
        vaults:[{vault_name:.vault.name,vault_role:.agent.vaultRole}]}' \
      "$agent_vault_policy")"
    agent_token="$(curl -fsS -H "Authorization: Bearer $session_token" \
      -H 'Content-Type: application/json' -d "$agent_body" \
      "$agent_vault_url/v1/agents" | jq -er '.av_agent_token')"
  elif [ "$agent_code" = "200" ]; then
    # 7. When the agent exists, reapply its declared instance-level role (for
    # Hermes, no-access) to correct any manual configuration drift.
    agent_role_body="$(jq -c '{role:.agent.role}' "$agent_vault_policy")"
    vault_role_body="$(jq -c '{role:.agent.vaultRole}' "$agent_vault_policy")"
    agent_vault_request POST "/v1/agents/$agent_name/role" "$agent_role_body"

    # 8. Reconcile membership in this specific vault. Update the existing vault
    # role (for Hermes, proxy), or add the agent when a 404 shows that membership
    # does not yet exist.
    vault_role_code="$(curl -sS -o /dev/null -w '%{http_code}' -X POST \
      -H "Authorization: Bearer $session_token" \
      -H 'Content-Type: application/json' -d "$vault_role_body" \
      "$agent_vault_url/v1/vaults/$vault_name/agents/$agent_name/role")"
    if [ "$vault_role_code" = "404" ]; then
      vault_agent_body="$(jq -c \
        '{name:.agent.name,role:.agent.vaultRole}' "$agent_vault_policy")"
      agent_vault_request POST "/v1/vaults/$vault_name/agents" "$vault_agent_body"
    elif [ "$vault_role_code" != "200" ]; then
      echo "agent-vault-config: vault agent role update failed (HTTP $vault_role_code)" >&2
      exit 1
    fi
  else
    echo "agent-vault-config: agent lookup failed (HTTP $agent_code)" >&2
    exit 1
  fi
}
