{ config, lib, pkgs, ... }:

let
  version = "0.39.0";

  agentVault = pkgs.stdenvNoCC.mkDerivation {
    pname = "agent-vault";
    inherit version;

    src = pkgs.fetchurl {
      url = "https://github.com/Infisical/agent-vault/releases/download/v${version}/agent-vault_${version}_linux_amd64.tar.gz";
      hash = "sha256-DZhiBa3GRtLx8dD/Ih+fTpR4XoButZ4rTzYJNCtr4lU=";
    };

    sourceRoot = ".";

    installPhase = ''
      runHook preInstall
      install -D -m 0555 agent-vault "$out/bin/agent-vault"
      runHook postInstall
    '';

    meta = {
      description = "HTTP credential proxy and vault for AI agents";
      homepage = "https://github.com/Infisical/agent-vault";
      license = lib.licenses.mit;
      mainProgram = "agent-vault";
      platforms = [ "x86_64-linux" ];
    };
  };
in

{
  users.groups.agent-vault = { };

  users.users.agent-vault = {
    isSystemUser = true;
    group = "agent-vault";
    extraGroups = [ "hermes" ];
    home = "/var/lib/agent-vault";
  };

  # This directory is visible as /workspace/.agent-vault inside Hermes command
  # containers. It contains only Hermes' broker identity, never upstream keys.
  systemd.tmpfiles.rules = [
    "d /var/lib/hermes/workspace/.agent-vault 2750 agent-vault hermes - -"
  ];

  # One env-format secret, kept out of the world-readable Nix store and fed to
  # the units via EnvironmentFile. Holds both AGENT_VAULT_MASTER_PASSWORD (the
  # KEK that unwraps the data key) and the AV_OWNER_* owner login for bootstrap.
  age.secrets.agent-vault = {
    file = ../../secrets/agent-vault.env.age;
    owner = "agent-vault";
    group = "agent-vault";
    mode = "0400";
  };

  systemd.services.agent-vault = {
    description = "Agent Vault credential proxy for AI agents";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    # Reload the vault when the secret changes.
    restartTriggers = [ config.age.secrets.agent-vault.file ];

    # DefaultDBPath is $HOME/.agent-vault/agent-vault.db; pin HOME so it lands in
    # the StateDirectory systemd creates and owns for the service user.
    environment = {
      HOME = "/var/lib/agent-vault";
      AGENT_VAULT_TELEMETRY = "false";
    };

    serviceConfig = {
      Type = "simple";
      User = "agent-vault";
      Group = "agent-vault";
      StateDirectory = "agent-vault";
      WorkingDirectory = "/var/lib/agent-vault";
      EnvironmentFile = config.age.secrets.agent-vault.path;
      # Listen on IPv4 interfaces so other machines on the home LAN can use the
      # web UI. The interface-specific firewall rule below limits access to the
      # Wi-Fi LAN; in particular, this does not open the port on Tailscale.
      ExecStart = "${lib.getExe agentVault} server --host 0.0.0.0 --port 14321";
      Restart = "on-failure";
      RestartSec = "5s";

      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      ReadWritePaths = [ "/var/lib/agent-vault" ];
      UMask = "0077";
    };
  };

  networking.firewall.interfaces.wlp2s0.allowedTCPPorts = [ 14321 ];

  # The owner account is DB state with no config-file/env seed, but the first
  # POST /v1/auth/register is auto-verified as owner (no code/SMTP). This oneshot
  # makes that call once so the whole setup stays declarative - no web-UI click.
  systemd.services.agent-vault-bootstrap = {
    description = "One-time owner registration for Agent Vault";
    after = [ "agent-vault.service" ];
    requires = [ "agent-vault.service" ];
    wantedBy = [ "multi-user.target" ];

    # Skip entirely once the owner has been created.
    unitConfig.ConditionPathExists = "!/var/lib/agent-vault/.owner-bootstrapped";

    path = [ pkgs.curl pkgs.jq pkgs.coreutils ];

    serviceConfig = {
      Type = "oneshot";
      User = "agent-vault";
      Group = "agent-vault";
      EnvironmentFile = config.age.secrets.agent-vault.path;
      ExecStart = pkgs.writeShellScript "agent-vault-bootstrap" ''
        set -eu
        url="http://127.0.0.1:14321"

        # Wait for the server to accept requests before registering.
        ready=false
        for _ in $(seq 1 60); do
          if curl -fsS "$url/health" >/dev/null 2>&1; then
            ready=true
            break
          fi
          sleep 1
        done
        if [ "$ready" != true ]; then
          echo "agent-vault-bootstrap: server did not become ready" >&2
          exit 1
        fi

        # jq encodes the password safely regardless of special characters.
        body="$(jq -n --arg e "$AV_OWNER_EMAIL" --arg p "$AV_OWNER_PASSWORD" \
          '{email:$e,password:$p}')"
        code="$(curl -sS -o /dev/null -w '%{http_code}' \
          -H 'Content-Type: application/json' -d "$body" "$url/v1/auth/register")"

        # Registration returns 201. If the database already has an owner but the
        # marker was lost, verify the declared credentials before recreating it.
        if [ "$code" != "201" ]; then
          code="$(curl -sS -o /dev/null -w '%{http_code}' \
            -H 'Content-Type: application/json' -d "$body" "$url/v1/auth/login")"
          if [ "$code" != "200" ]; then
            echo "agent-vault-bootstrap: owner registration/login failed (HTTP $code)" >&2
            exit 1
          fi
        fi

        touch /var/lib/agent-vault/.owner-bootstrapped
      '';
    };
  };

  # Reconcile the trusted configuration on every boot and whenever either the
  # declaration or encrypted environment changes. Unlike owner registration,
  # this intentionally has no marker: later rebuilds must update the token and
  # policy already stored in Agent Vault's database.
  systemd.services.agent-vault-config = {
    description = "Reconcile declarative Agent Vault configuration";
    after = [ "agent-vault-bootstrap.service" ];
    requires = [ "agent-vault.service" ];
    wantedBy = [ "multi-user.target" ];
    restartTriggers = [ config.age.secrets.agent-vault.file ];

    path = [ pkgs.curl pkgs.jq pkgs.coreutils ];

    serviceConfig = {
      Type = "oneshot";
      User = "agent-vault";
      Group = "agent-vault";
      EnvironmentFile = config.age.secrets.agent-vault.path;
      ExecStart = pkgs.writeShellScript "agent-vault-config" ''
        set -eu
        url="http://127.0.0.1:14321"

        ready=false
        for _ in $(seq 1 60); do
          if curl -fsS "$url/health" >/dev/null 2>&1; then
            ready=true
            break
          fi
          sleep 1
        done
        if [ "$ready" != true ]; then
          echo "agent-vault-config: server did not become ready" >&2
          exit 1
        fi

        login_body="$(jq -n --arg e "$AV_OWNER_EMAIL" --arg p "$AV_OWNER_PASSWORD" \
          '{email:$e,password:$p,device_label:"declarative-config"}')"
        session_token="$(curl -fsS -H 'Content-Type: application/json' \
          -d "$login_body" "$url/v1/auth/login" | jq -er '.token')"

        request() {
          method="$1"
          endpoint="$2"
          body="$3"
          curl -fsS -X "$method" -H "Authorization: Bearer $session_token" \
            -H 'Content-Type: application/json' -d "$body" "$url$endpoint" \
            >/dev/null
        }

        # Creating an existing vault returns 409; every subsequent operation is
        # a convergent update, so only ignore that one expected response.
        create_code="$(curl -sS -o /dev/null -w '%{http_code}' -X POST \
          -H "Authorization: Bearer $session_token" \
          -H 'Content-Type: application/json' -d '{"name":"hermes"}' \
          "$url/v1/vaults")"
        if [ "$create_code" != "201" ] && [ "$create_code" != "409" ]; then
          echo "agent-vault-config: vault creation failed (HTTP $create_code)" >&2
          exit 1
        fi

        credential_body="$(jq -n --arg token "$GITLAB_TOKEN" \
          '{vault:"hermes",credentials:{GITLAB_TOKEN:$token}}')"
        request POST /v1/credentials "$credential_body"

        request PUT /v1/vaults/hermes/services \
          '{"services":[{"name":"gitlab-api","host":"gitlab.com","path":"/api/v4/*","auth":{"type":"api-key","key":"GITLAB_TOKEN","header":"PRIVATE-TOKEN"}}]}'

        request PATCH /v1/vaults/hermes/settings \
          '{"unmatched_host_policy":"passthrough"}'

        # Create the long-lived broker identity once, then continuously assert
        # its least-privileged instance and vault roles.
        agent_code="$(curl -sS -o /dev/null -w '%{http_code}' \
          -H "Authorization: Bearer $session_token" "$url/v1/agents/hermes")"
        agent_token=""
        if [ "$agent_code" = "404" ]; then
          agent_body='{"name":"hermes","role":"no-access","vaults":[{"vault_name":"hermes","vault_role":"proxy"}]}'
          agent_token="$(curl -fsS -H "Authorization: Bearer $session_token" \
            -H 'Content-Type: application/json' -d "$agent_body" \
            "$url/v1/agents" | jq -er '.av_agent_token')"
        elif [ "$agent_code" = "200" ]; then
          request POST /v1/agents/hermes/role '{"role":"no-access"}'
          request POST /v1/vaults/hermes/agents/hermes/role '{"role":"proxy"}'
        else
          echo "agent-vault-config: agent lookup failed (HTTP $agent_code)" >&2
          exit 1
        fi

        # Preserve a working token across rebuilds. If the handoff file is lost
        # or its token is revoked, rotate the broker identity and recreate it.
        client_env=/var/lib/hermes/workspace/.agent-vault/env
        if [ -z "$agent_token" ] && [ -r "$client_env" ]; then
          current_token="$(sed -n 's/^AGENT_VAULT_TOKEN=//p' "$client_env")"
          if [ -n "$current_token" ] && curl -fsS \
            -H "Authorization: Bearer $current_token" -H 'X-Vault: hermes' \
            "$url/discover" >/dev/null 2>&1; then
            agent_token="$current_token"
          fi
        fi
        if [ -z "$agent_token" ]; then
          agent_token="$(curl -fsS -X POST \
            -H "Authorization: Bearer $session_token" \
            -H 'Content-Type: application/json' -d '{}' \
            "$url/v1/agents/hermes/rotate" | jq -er '.av_agent_token')"
        fi

        ca_tmp="$(mktemp /var/lib/hermes/workspace/.agent-vault/.ca.pem.XXXXXX)"
        curl -fsS "$url/v1/mitm/ca.pem" > "$ca_tmp"
        chmod 0640 "$ca_tmp"
        mv "$ca_tmp" /var/lib/hermes/workspace/.agent-vault/ca.pem

        env_tmp="$(mktemp /var/lib/hermes/workspace/.agent-vault/.env.XXXXXX)"
        chmod 0640 "$env_tmp"
        proxy_url="http://$agent_token:hermes@host.containers.internal:14322"
        printf 'AGENT_VAULT_ADDR=http://host.containers.internal:14321\n' > "$env_tmp"
        printf 'AGENT_VAULT_VAULT=hermes\n' >> "$env_tmp"
        printf 'AGENT_VAULT_TOKEN=%s\n' "$agent_token" >> "$env_tmp"
        printf 'HTTPS_PROXY=%s\n' "$proxy_url" >> "$env_tmp"
        printf 'HTTP_PROXY=%s\n' "$proxy_url" >> "$env_tmp"
        printf 'NO_PROXY=localhost,127.0.0.1,host.containers.internal\n' >> "$env_tmp"
        printf 'NODE_USE_ENV_PROXY=1\n' >> "$env_tmp"
        printf 'OPENCLAW_PROXY_URL=%s\n' "$proxy_url" >> "$env_tmp"
        printf 'SSL_CERT_FILE=/workspace/.agent-vault/ca.pem\n' >> "$env_tmp"
        printf 'NODE_EXTRA_CA_CERTS=/workspace/.agent-vault/ca.pem\n' >> "$env_tmp"
        printf 'REQUESTS_CA_BUNDLE=/workspace/.agent-vault/ca.pem\n' >> "$env_tmp"
        printf 'CURL_CA_BUNDLE=/workspace/.agent-vault/ca.pem\n' >> "$env_tmp"
        printf 'GIT_SSL_CAINFO=/workspace/.agent-vault/ca.pem\n' >> "$env_tmp"
        printf 'DENO_CERT=/workspace/.agent-vault/ca.pem\n' >> "$env_tmp"
        mv "$env_tmp" "$client_env"
      '';
    };
  };

  # The gateway receives only its Agent Vault identity, never GITLAB_TOKEN.
  # A failed reconciliation prevents Hermes from starting with stale access.
  systemd.services.hermes-agent = {
    after = [ "agent-vault-config.service" ];
    requires = [ "agent-vault-config.service" ];
  };

  # Podman reads this host-side env file while constructing every command
  # container. Paths inside it refer to the existing /workspace bind mount.
  services.hermes-agent.settings.terminal.docker_extra_args = [
    "--env-file=/var/lib/hermes/workspace/.agent-vault/env"
  ];

  environment.systemPackages = [ agentVault ];
}
