# Shared Agent Vault management API operations. This file is sourced by the
# reconciliation entrypoint, so assigned output variables remain in that shell.

# Input:
#   agent_vault_url  Management API base URL, such as http://127.0.0.1:14321.
# Output:
#   None. Exits if the server does not become healthy within 60 seconds.
agent_vault_wait() {
  ready=false
  for _ in $(seq 1 60); do
    if curl -fsS "$agent_vault_url/health" >/dev/null 2>&1; then
      ready=true
      break
    fi
    sleep 1
  done
  if [ "$ready" != true ]; then
    echo "agent-vault-config: server did not become ready" >&2
    exit 1
  fi
}

# Inputs:
#   agent_vault_url   Management API base URL.
#   AV_OWNER_EMAIL    Owner login email from the protected Agenix env file.
#   AV_OWNER_PASSWORD Owner login password from the protected Agenix env file.
# Output:
#   session_token     Short-lived token returned by POST /v1/auth/login. It is
#                     used only to authorize reconciliation API calls and is
#                     never written to the Hermes handoff file.
agent_vault_login() {
  login_body="$(jq -n --arg e "$AV_OWNER_EMAIL" --arg p "$AV_OWNER_PASSWORD" \
    '{email:$e,password:$p,device_label:"declarative-config"}')"
  session_token="$(curl -fsS -H 'Content-Type: application/json' \
    -d "$login_body" "$agent_vault_url/v1/auth/login" | jq -er '.token')"
}

# Positional inputs:
#   $1  HTTP method.
#   $2  API path relative to agent_vault_url.
#   $3  JSON request body.
# Implicit inputs:
#   agent_vault_url  Management API base URL.
#   session_token    Owner-session token created by agent_vault_login.
# Output:
#   None. Discards a successful response body and fails on HTTP errors.
agent_vault_request() {
  method="$1"
  endpoint="$2"
  body="$3"
  curl -fsS -X "$method" -H "Authorization: Bearer $session_token" \
    -H 'Content-Type: application/json' -d "$body" \
    "$agent_vault_url$endpoint" >/dev/null
}
