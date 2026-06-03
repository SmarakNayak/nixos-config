{ config, lib, pkgs, ... }:

# Give the Hermes agent read-only email and (Google) calendar access via the
# provider REST APIs. This is the email/calendar analogue of
# hermes-github-app.nix: a host-side systemd timer holds the long-lived OAuth
# refresh tokens (Agenix secrets, never copied into the sandbox) and mints
# short-lived (~1h) access tokens into the workspace mount. Generated commands
# read those tokens from /workspace/.hermes-mail/<account>/access-token and call
# the Gmail / Calendar / Microsoft Graph REST APIs directly.
#
# Why REST and not IMAP: Gmail's IMAP/SMTP only accept the full-access
# https://mail.google.com/ scope. Read-only mail exists ONLY on the REST APIs
# (gmail.readonly, Graph Mail.Read), so the agent must speak REST.
#
# Refresh-token longevity differs by provider:
#   - Google: a Production-status OAuth app's refresh token never expires
#     (6-month inactivity only) and Google reuses the same one on refresh, so it
#     is a static read-only Agenix input with no per-host state.
#   - Microsoft: every refresh token has a fixed 90-day lifetime FROM ITS OWN
#     ISSUANCE — redeeming it does not reset that clock. Each redemption returns
#     a NEW token with a fresh 90-day window, so we must ADOPT the successor each
#     time to live indefinitely. The broker keeps the current token in a mutable
#     host file (see `refreshTokenDir`) and rewrites it on every rotation. This token is
#     deliberately NOT in Agenix: it would go stale within 90 days (the live
#     value lives only in the host file), and pushing the rotating value back to
#     git would mean giving this agent host write access to the config repo — a
#     worse trade than a rare manual re-mint. Cost: if /var/lib is wiped (OS
#     reinstall) or the broker is offline >90 days, re-run the one-time hotmail
#     mint. Google, by contrast, is fully reproducible from master.key + repo.
#
# ONE-TIME MANUAL SETUP (see also the repo plan / README):
#   1. Google Cloud: create ONE OAuth "Desktop app" client used by all three
#      Gmail accounts; enable the Gmail API + Google Calendar API; request scopes
#      `gmail.readonly` and `calendar.events`; PUBLISH the consent screen to
#      "In production" (unverified is fine for personal use) so refresh tokens
#      do not expire after 7 days. Put the client ID in `googleClientId` below.
#   2. Azure: register an app for personal Microsoft accounts (`consumers`) as a
#      PUBLIC client (no secret), delegated `Mail.Read` + `offline_access`. Put
#      the client ID in `msClientId` below.
#   3. Mint + store the refresh tokens with ./hermes-oauth-mint.sh, which mints
#      (via hermes-oauth-mint.py) AND stores in one step:
#        bash hosts/antec-pc/hermes-oauth-mint.sh google casual   # + proper, work
#        sudo bash hosts/antec-pc/hermes-oauth-mint.sh microsoft
#      Google tokens land in secrets/*.age (agenix); the Microsoft token lands in
#      /var/lib/hermes/oauth/ms-hotmail.refresh. The Google client secret must
#      already be stored once: cd secrets && nix run github:ryantm/agenix -- \
#        -e google-oauth-client-secret.age

let
  # Public application identifiers — not secret (like githubAppId in
  # hermes-github-app.nix). REPLACE these with the IDs from the registered apps.
  googleClientId = "505807432826-6jpajmrp2od0j1clnmuq59tdbnnov0c8.apps.googleusercontent.com";
  msClientId = "0423ac40-9ca9-48e2-9636-56d488ab24ef";

  # Email addresses are sourced from the (git-agecrypt) secrets file rather than
  # hardcoded here, mirroring modules/email.nix. The hashFile guard keeps eval
  # working even when the file is still encrypted in the working tree.
  secretsFile = ../../secrets/email.nix;
  decryptedEmailHash = "4b324ca2f223d5f25bbdcd793dbfa4ef9698e1cae166fceecc6c095f26a4c268";
  isDecrypted = builtins.hashFile "sha256" secretsFile == decryptedEmailHash;
  emails = if isDecrypted then import secretsFile else {
    gmail1 = "gmail1@example.com";
    gmail2 = "gmail2@example.com";
    gmail3 = "gmail3@example.com";
    hotmail = "hotmail@example.com";
  };

  # Host path the broker writes to, and the path the agent sees it at inside the
  # sandbox (hermes.nix mounts /var/lib/hermes/workspace -> /workspace). The
  # manifest must advertise the CONTAINER path, since the agent reads it there.
  workspaceRoot = "/var/lib/hermes/workspace/.hermes-mail";
  containerRoot = "/workspace/.hermes-mail";
  # Host-side mutable store for rotating refresh tokens (Microsoft only). Lives
  # outside the workspace mount so generated commands never see refresh tokens.
  refreshTokenDir = "/var/lib/hermes/oauth";

  # Account table. Google accounts carry `secret` (the Agenix secret holding a
  # static refresh token) + `secretFile` (the .age path). Microsoft's rotating
  # token is NOT in Agenix — it lives only in the host state file (see header).
  # Scopes are informational (fixed at consent time) but recorded for the manifest.
  accounts = {
    google-casual = {
      provider = "google";
      address = emails.gmail1;
      secret = "hermes-google-refresh-casual";
      secretFile = ../../secrets/google-refresh-casual.age;
      scopes = [ "gmail.readonly" "calendar.events" ];
    };
    google-proper = {
      provider = "google";
      address = emails.gmail2;
      secret = "hermes-google-refresh-proper";
      secretFile = ../../secrets/google-refresh-proper.age;
      scopes = [ "gmail.readonly" "calendar.events" ];
    };
    google-work = {
      provider = "google";
      address = emails.gmail3;
      secret = "hermes-google-refresh-work";
      secretFile = ../../secrets/google-refresh-work.age;
      scopes = [ "gmail.readonly" "calendar.events" ];
    };
    ms-hotmail = {
      provider = "microsoft";
      address = emails.hotmail;
      scopes = [ "Mail.Read" "offline_access" ];
    };
  };

  googleAccounts = lib.filterAttrs (_: acct: acct.provider == "google") accounts;

  # Per-account refresh-token Agenix secrets (Google only), owned by hermes.
  refreshSecrets = lib.mapAttrs' (_: acct:
    lib.nameValuePair acct.secret {
      file = acct.secretFile;
      owner = "hermes";
      group = "hermes";
      mode = "0400";
    }) googleAccounts;

  # Machine-readable map the agent reads to know which token is which account.
  manifest = pkgs.writeText "hermes-mail-manifest.json" (builtins.toJSON (
    lib.mapAttrs (name: acct: {
      inherit (acct) provider address scopes;
      access_token = "${containerRoot}/${name}/access-token";
    }) accounts
  ));

  # Usage + lifecycle doc. Written both to /workspace/HERMES.md (Hermes loads it
  # into the system prompt from the terminal cwd) and to .hermes-mail/README.md
  # (so it sits next to the tokens for anything that inspects that directory).
  hermesMd = pkgs.writeText "hermes-mail-readme.md" ''
    # Mail & calendar access

    You have short-lived OAuth access tokens for the operator's email and
    calendar accounts. The account → token-file map is in
    `.hermes-mail/manifest.json`; each entry's `access_token` field is a file
    holding a bearer token. Use it as:

        AUTH="Authorization: Bearer $(cat .hermes-mail/<account>/access-token)"

    Mail is READ-ONLY. Calendar (Google only) is read/write (events).

    ## Token lifecycle — READ THIS BEFORE ASSUMING ANYTHING IS BROKEN
    - These are SHORT-LIVED access tokens (~1 hour). A host-side service
      refreshes them automatically every 45 minutes — you do not manage refresh.
    - ALWAYS re-read the token file immediately before each request. Never cache
      the token's value in a variable across calls; re-read it each time.
    - The long-lived refresh tokens are deliberately NOT in this sandbox — they
      live on the host and never appear here. You cannot and need not perform
      token refresh yourself, and there is nothing to "fix" about that.
    - A 401 almost always means you used a stale/cached value, or you hit the
      brief window during a refresh. Just re-read the file and retry once before
      concluding anything is wrong.

    ## Google accounts (google-casual, google-proper, google-work)
    - Read mail (read-only):
        curl -s -H "$AUTH" \
          'https://gmail.googleapis.com/gmail/v1/users/me/messages?maxResults=10'
        curl -s -H "$AUTH" \
          'https://gmail.googleapis.com/gmail/v1/users/me/messages/<id>?format=full'
    - Calendar (read/write events):
        curl -s -H "$AUTH" \
          'https://www.googleapis.com/calendar/v3/calendars/primary/events'
        curl -s -X POST -H "$AUTH" -H 'Content-Type: application/json' \
          -d '{"summary":"...","start":{...},"end":{...}}' \
          'https://www.googleapis.com/calendar/v3/calendars/primary/events'

    ## Microsoft account (ms-hotmail) — mail read-only via Graph
        curl -s -H "$AUTH" \
          'https://graph.microsoft.com/v1.0/me/messages?$top=10'

    If `curl`/`jq`/`python3` are missing in this sandbox, install them with nix
    (e.g. `nix shell nixpkgs#curl nixpkgs#jq`).
  '';

  # One shared bash helper used by the systemd unit. Generated commands never
  # see the refresh tokens or client secret — only the minted access tokens.
  refreshScript = pkgs.writeShellScript "hermes-mail-token-refresh" ''
    set -euo pipefail
    umask 077

    workspace_root=${lib.escapeShellArg workspaceRoot}
    refresh_token_dir=${lib.escapeShellArg refreshTokenDir}
    ${pkgs.coreutils}/bin/install -d -m 0700 "$workspace_root"
    ${pkgs.coreutils}/bin/install -d -m 0700 "$refresh_token_dir"

    # post_token <url> <jq --arg pairs...> — emit the response body on stdout.
    # The form body is assembled with jq (correct URL-encoding) and piped to curl
    # on stdin so the body never lands on disk. On HTTP error curl --fail exits
    # non-zero; with pipefail that propagates and (set -e) aborts the caller.
    post_token() {
      url="$1"; shift
      # --join-output (not --raw-output): the urlencoded body must have NO
      # trailing newline, or curl --data-binary sends it and the server reads
      # the final value as e.g. "refresh_token\n" → 400.
      ${pkgs.jq}/bin/jq --null-input --join-output "$@" \
        '$ARGS.named | to_entries | map((.key|@uri)+"="+(.value|@uri)) | join("&")' \
        | ${pkgs.curl}/bin/curl --fail --silent --show-error \
            --request POST \
            --header "Content-Type: application/x-www-form-urlencoded" \
            --data-binary @- \
            "$url"
    }

    # write_atomic <dest> <mode> — write stdin to <dest> via a sibling temp + mv.
    # The rename is atomic on the same filesystem, so readers (and the sole copy
    # of a refresh token) never see a partial write. Callers only reach this
    # after a successful exchange, so a failed refresh never overwrites a good
    # token — set -e aborts before we get here.
    write_atomic() {
      dest="$1"; mode="$2"
      ${pkgs.coreutils}/bin/install -d -m 0700 "$(${pkgs.coreutils}/bin/dirname "$dest")"
      ${pkgs.coreutils}/bin/cat > "$dest.new"
      ${pkgs.coreutils}/bin/chmod "$mode" "$dest.new"
      ${pkgs.coreutils}/bin/mv -f "$dest.new" "$dest"
    }

    # mint_google <account> <refresh-token-path> <client-secret-path>
    mint_google() {
      account="$1"; refresh_path="$2"; secret_path="$3"
      resp="$(post_token "https://oauth2.googleapis.com/token" \
        --arg client_id ${lib.escapeShellArg googleClientId} \
        --arg client_secret "$(${pkgs.coreutils}/bin/cat "$secret_path")" \
        --arg refresh_token "$(${pkgs.coreutils}/bin/cat "$refresh_path")" \
        --arg grant_type refresh_token)"
      # Extract first (jq --exit-status fails if absent) so we only overwrite the
      # live token once we actually have a new one.
      access="$(${pkgs.coreutils}/bin/printf '%s' "$resp" | ${pkgs.jq}/bin/jq --exit-status --raw-output '.access_token')"
      ${pkgs.coreutils}/bin/printf '%s' "$access" | write_atomic "$workspace_root/$account/access-token" 0400
    }

    # mint_microsoft <account>
    # Microsoft rotates refresh tokens with a fixed 90-day window per token, so
    # we adopt the successor each run: read the current token from the mutable
    # refresh-token file, exchange it, then persist the newly-issued token back.
    # That file is bootstrapped once by the manual mint (see header); it is the
    # sole store for this credential (deliberately not in Agenix).
    mint_microsoft() {
      account="$1"
      refresh_file="$refresh_token_dir/$account.refresh"
      if [ ! -s "$refresh_file" ]; then
        echo "hermes-mail: $refresh_file missing — run the one-time hotmail mint" >&2
        return 1
      fi
      resp="$(post_token "https://login.microsoftonline.com/consumers/oauth2/v2.0/token" \
        --arg client_id ${lib.escapeShellArg msClientId} \
        --arg scope "https://graph.microsoft.com/Mail.Read offline_access" \
        --arg refresh_token "$(${pkgs.coreutils}/bin/cat "$refresh_file")" \
        --arg grant_type refresh_token)"
      # Require BOTH fields before writing anything, so a malformed response never
      # overwrites the access token or truncates the sole refresh-token copy.
      access="$(${pkgs.coreutils}/bin/printf '%s' "$resp" | ${pkgs.jq}/bin/jq --exit-status --raw-output '.access_token')"
      new_refresh="$(${pkgs.coreutils}/bin/printf '%s' "$resp" | ${pkgs.jq}/bin/jq --exit-status --raw-output '.refresh_token')"
      ${pkgs.coreutils}/bin/printf '%s' "$access" | write_atomic "$workspace_root/$account/access-token" 0400
      ${pkgs.coreutils}/bin/printf '%s' "$new_refresh" | write_atomic "$refresh_file" 0600
    }

    # Per-account invocations (generated from the Nix account table). A single
    # account failing must not block the others.
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: acct:
      if acct.provider == "google" then
        "mint_google ${lib.escapeShellArg name} ${lib.escapeShellArg config.age.secrets.${acct.secret}.path} ${lib.escapeShellArg config.age.secrets.hermes-google-client-secret.path} || echo \"hermes-mail: ${name} refresh failed\" >&2"
      else
        "mint_microsoft ${lib.escapeShellArg name} || echo \"hermes-mail: ${name} refresh failed\" >&2"
    ) accounts)}

    # Drop the account manifest and usage/lifecycle doc alongside the tokens,
    # plus HERMES.md in the workspace root (loaded into the agent's prompt).
    ${pkgs.coreutils}/bin/install -m 0444 ${manifest} "$workspace_root/manifest.json"
    ${pkgs.coreutils}/bin/install -m 0444 ${hermesMd} "$workspace_root/README.md"
    ${pkgs.coreutils}/bin/install -m 0444 ${hermesMd} /var/lib/hermes/workspace/HERMES.md
  '';
in

{
  age.secrets = refreshSecrets // {
    hermes-google-client-secret = {
      file = ../../secrets/google-oauth-client-secret.age;
      owner = "hermes";
      group = "hermes";
      mode = "0400";
    };
  };

  systemd.tmpfiles.rules = [
    "d ${workspaceRoot} 0700 hermes hermes -"
    "d ${refreshTokenDir} 0700 hermes hermes -"
  ];

  systemd.services.hermes-mail-token = {
    description = "Refresh Hermes mail/calendar OAuth access tokens";
    after = [ "agenix.service" ];
    wants = [ "agenix.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "hermes";
      Group = "hermes";
      UMask = "0077";
      ExecStart = refreshScript;
    };
  };

  systemd.timers.hermes-mail-token = {
    description = "Periodically refresh Hermes mail/calendar OAuth access tokens";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "0";
      OnUnitActiveSec = "45m";
      Unit = "hermes-mail-token.service";
    };
  };

  # Mint tokens before the agent starts, and restart it when a refresh-token
  # secret changes (mirrors hermes-github-app.nix).
  systemd.services.hermes-agent = {
    after = [ "hermes-mail-token.service" ];
    wants = [ "hermes-mail-token.service" ];
    restartTriggers = map (acct: config.age.secrets.${acct.secret}.file)
      (lib.attrValues googleAccounts);
  };
}
