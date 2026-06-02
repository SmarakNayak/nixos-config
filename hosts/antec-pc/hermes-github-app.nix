{ config, lib, pkgs, ... }:

let
  githubAppId = "3911988";
  githubInstallationId = "136716951";

  # Git asks this helper for HTTPS credentials when generated commands clone,
  # fetch, or push. It returns the current short-lived installation token only
  # for github.com; it never handles the App private key.
  githubCredentialHelper = pkgs.writeText "hermes-github-credential" ''
    #!/bin/sh
    set -eu

    operation="''${1:-get}"
    test "$operation" = get || exit 0

    host=
    while IFS= read -r line && test -n "$line"; do
      case "$line" in
        host=*) host="''${line#host=}" ;;
      esac
    done

    test "$host" = github.com || exit 0
    printf 'username=x-access-token\n'
    printf 'password=%s\n' "$(cat /workspace/.hermes-github/token)"
  '';

  # Make gh use the same refreshed installation token as Git without exposing
  # it as a permanent environment variable in every command container.
  hermesGh = pkgs.writeText "hermes-github-gh" ''
    #!/bin/sh
    set -eu

    export GH_TOKEN="$(cat /workspace/.hermes-github/token)"
    for gh in /root/.nix-profile/bin/gh /nix/var/nix/profiles/default/bin/gh /usr/local/bin/gh /usr/bin/gh /bin/gh; do
      test -x "$gh" || continue
      exec "$gh" "$@"
    done

    printf 'gh is not installed in the Hermes command container\n' >&2
    exit 127
  '';

  # Point HTTPS operations for github.com at the helper above. Hermes receives
  # this config through GIT_CONFIG_GLOBAL inside generated command containers.
  githubGitConfig = pkgs.writeText "hermes-github-gitconfig" ''
    [credential "https://github.com"]
      helper = /workspace/.hermes-github/credential-helper
  '';
in

{
  # Keep the long-lived GitHub App private key outside Hermes command
  # containers. The gateway account mints a short-lived installation token
  # before its one-hour expiry.
  age.secrets.hermes-github-app-private-key = {
    file = ../../secrets/smarak-agent-github-app.age;
    owner = "hermes";
    group = "hermes";
    mode = "0400";
  };

  # GitHub Apps use a two-step authentication flow: sign a JWT with the
  # long-lived private key, then exchange it for an installation token that
  # expires after about one hour. Only the resulting token enters the shared
  # workspace mounted into generated command containers.
  systemd.services.hermes-github-app-token = {
    description = "Refresh the Hermes GitHub App installation token";
    after = [ "agenix.service" ];
    wants = [ "agenix.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "hermes";
      Group = "hermes";
      UMask = "0077";
    };
    script = ''
      set -eu

      # JWT segments use URL-safe base64 without the normal trailing padding.
      # This helper converts stdin into that representation.
      b64url() {
        ${pkgs.openssl}/bin/openssl base64 -A |
          ${pkgs.coreutils}/bin/tr '+/' '-_' |
          ${pkgs.coreutils}/bin/tr -d '='
      }

      # Prove ownership of the GitHub App by constructing a short-lived JWT:
      #   header.payload.signature
      #
      # iat starts one minute in the past to tolerate minor clock skew. GitHub
      # permits App JWTs to live for at most ten minutes, so this one lasts nine.
      # iss identifies the GitHub App that owns the private signing key.
      now="$(${pkgs.coreutils}/bin/date +%s)"
      header="$(printf '%s' '{"alg":"RS256","typ":"JWT"}' | b64url)"
      payload="$(printf '{"iat":%s,"exp":%s,"iss":"%s"}' "$((now - 60))" "$((now + 540))" ${lib.escapeShellArg githubAppId} | b64url)"
      unsigned_token="$header.$payload"

      # Sign the encoded header and payload with the App private key decrypted
      # by Agenix. The PEM remains on the host and is never copied to workspace.
      signature="$(printf '%s' "$unsigned_token" |
        ${pkgs.openssl}/bin/openssl dgst -sha256 -sign ${config.age.secrets.hermes-github-app-private-key.path} -binary |
        b64url)"
      jwt="$unsigned_token.$signature"

      # Materialize the command-container integration inside the existing
      # workspace mount. These files contain no long-lived credential:
      # - credential-helper supplies the refreshed token to HTTPS Git commands.
      # - gh wraps GitHub CLI so it reads the same refreshed token.
      # - gitconfig tells Git to call credential-helper for github.com.
      ${pkgs.coreutils}/bin/install -d -m 0700 \
        /var/lib/hermes/workspace/.hermes-github
      ${pkgs.coreutils}/bin/install -m 0500 \
        ${githubCredentialHelper} /var/lib/hermes/workspace/.hermes-github/credential-helper
      ${pkgs.coreutils}/bin/install -m 0500 \
        ${hermesGh} /var/lib/hermes/workspace/.hermes-github/gh
      ${pkgs.coreutils}/bin/install -m 0400 \
        ${githubGitConfig} /var/lib/hermes/workspace/.hermes-github/gitconfig

      # Exchange the App JWT for an installation token scoped by the GitHub App
      # installation's repository selection and permissions. GitHub returns a
      # token with an approximately one-hour lifetime; jq extracts that token.
      token="$(${pkgs.curl}/bin/curl --fail --silent --show-error \
        --request POST \
        --header "Accept: application/vnd.github+json" \
        --header "Authorization: Bearer $jwt" \
        --header "X-GitHub-Api-Version: 2026-03-10" \
        "https://api.github.com/app/installations/${githubInstallationId}/access_tokens" |
        ${pkgs.jq}/bin/jq --exit-status --raw-output .token)"

      # Replace the workspace token only after GitHub returned a valid token.
      # install writes the final file with read-only permissions for its owner.
      # The temporary file is removed whether the script succeeds or fails.
      token_file="$(${pkgs.coreutils}/bin/mktemp)"
      trap '${pkgs.coreutils}/bin/rm -f "$token_file"' EXIT
      printf '%s\n' "$token" > "$token_file"
      ${pkgs.coreutils}/bin/install -D -m 0400 \
        "$token_file" /var/lib/hermes/workspace/.hermes-github/token
    '';
  };

  # Refresh with margin before GitHub's one-hour installation-token expiry.
  systemd.timers.hermes-github-app-token = {
    description = "Periodically refresh the Hermes GitHub App token";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "0";
      OnUnitActiveSec = "45m";
      Unit = "hermes-github-app-token.service";
    };
  };

  # Reuse the existing /var/lib/hermes/workspace:/workspace mount declared in
  # hermes.nix. Generated commands see the short-lived token and helper scripts,
  # but the App private key remains outside their container filesystem.
  services.hermes-agent.settings.terminal = {
    # Use the short-lived token for HTTPS Git credentials and gh. The App
    # private key remains on the host.
    docker_extra_args = [
      "--env=GIT_CONFIG_GLOBAL=/workspace/.hermes-github/gitconfig"
      "--env=PATH=/workspace/.hermes-github:/root/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    ];
  };

  systemd.services.hermes-agent = {
    after = [ "hermes-github-app-token.service" ];
    wants = [ "hermes-github-app-token.service" ];
    restartTriggers = [
      config.age.secrets.hermes-github-app-private-key.file
    ];
  };
}
