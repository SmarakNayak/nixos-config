{ config, lib, pkgs, ... }:

let
  version = "0.39.0";
  policy = import ./agent-vault-policy.nix;
  policyFile = pkgs.writeText "agent-vault-policy.json" (builtins.toJSON policy);
  apiScript = pkgs.writeText "agent-vault-api.sh"
    (builtins.readFile ./agent-vault-scripts/agent-vault-api.sh);
  policyScript = pkgs.writeText "agent-vault-policy.sh"
    (builtins.readFile ./agent-vault-scripts/agent-vault-policy.sh);
  hermesHandoffScript = pkgs.writeText "agent-vault-hermes-handoff.sh"
    (builtins.readFile ./agent-vault-scripts/agent-vault-hermes-handoff.sh);

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
  # the units via EnvironmentFile. Holds AGENT_VAULT_MASTER_PASSWORD (the KEK
  # that unwraps the data key), the AV_OWNER_* login, and upstream credentials
  # referenced by environment name in agent-vault-policy.nix.
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
      # Listen on IPv4 interfaces for the local Hermes container and the web UI.
      # The interface-specific firewall rules below expose it on Wi-Fi and
      # Tailscale, but not on unrelated interfaces.
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
  networking.firewall.interfaces.${config.services.tailscale.interfaceName}.allowedTCPPorts = [ 14321 ];

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
    restartTriggers = [
      config.age.secrets.agent-vault.file
      policyFile
    ];

    path = [ pkgs.curl pkgs.jq pkgs.coreutils ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "agent-vault";
      Group = "agent-vault";
      EnvironmentFile = config.age.secrets.agent-vault.path;
      ExecStart = pkgs.writeShellScript "agent-vault-config" ''
        set -eu
        agent_vault_url=http://127.0.0.1:14321
        agent_vault_policy=${lib.escapeShellArg policyFile}
        agent_vault_system_ca=${lib.escapeShellArg "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"}
        vault_name="$(jq -er '.vault.name' "$agent_vault_policy")"
        agent_name="$(jq -er '.agent.name' "$agent_vault_policy")"

        . ${lib.escapeShellArg apiScript}
        . ${lib.escapeShellArg policyScript}
        . ${lib.escapeShellArg hermesHandoffScript}

        agent_vault_wait
        agent_vault_login
        agent_vault_reconcile_policy
        agent_vault_write_hermes_handoff
      '';
    };
  };

  # The gateway receives only its Agent Vault identity, never GITLAB_TOKEN.
  # A failed reconciliation prevents Hermes from starting with stale access.
  systemd.services.hermes-agent = {
    after = [ "agent-vault-config.service" ];
    requires = [ "agent-vault-config.service" ];
  };

  # Make the combined public + Agent Vault bundle the command containers'
  # system trust store. Most OpenSSL/libcurl consumers (including Python, Git,
  # curl, and Nix) then discover it without application-specific environment
  # overrides. Keep the env file for proxy credentials and runtimes with their
  # own trust stores.
  services.hermes-agent.settings.terminal = {
    docker_extra_args = [
      "--env-file=/var/lib/hermes/workspace/.agent-vault/env"
      "--volume=/var/lib/hermes/workspace/.agent-vault/ca-bundle.pem:/etc/ssl/certs/ca-bundle.crt:ro"
      "--volume=/var/lib/hermes/workspace/.agent-vault/ca-bundle.pem:/etc/ssl/certs/ca-certificates.crt:ro"
      "--volume=/var/lib/hermes/workspace/.agent-vault/ca-bundle.pem:/etc/ssl/cert.pem:ro"
    ];
  };

  environment.systemPackages = [ agentVault ];
}
