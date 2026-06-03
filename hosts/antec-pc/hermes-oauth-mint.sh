#!/usr/bin/env bash
# Mint AND store an OAuth refresh token for Hermes mail/calendar in one step —
# wraps hermes-oauth-mint.py and handles the storage that used to be manual.
#
#   bash hosts/antec-pc/hermes-oauth-mint.sh google <casual|proper|work>
#   sudo bash hosts/antec-pc/hermes-oauth-mint.sh microsoft
#
# Google: opens a browser (sign in as the matching account), then encrypts the
#   refresh token straight into secrets/google-refresh-<label>.age (agenix) and
#   git-stages it. The Google client secret is read from its existing agenix
#   secret, so you don't pass it. Run `nixos-rebuild` afterwards to deploy.
#   Can run on ANY machine that has this repo + the age master key.
# Microsoft: prints a device-code URL, then writes the rotating refresh token to
#   /var/lib/hermes/oauth/ms-hotmail.refresh (owner hermes). Needs root → sudo.
#   MUST be run ON antec-pc — it writes a file on that host's filesystem, not
#   into the repo. No rebuild needed; the broker picks it up on its next run.
#
# The script re-execs itself inside `nix shell` so age + python3 are available
# (NixOS has neither globally).
set -euo pipefail

# Non-secret identifiers — same values inlined in hermes-mail.nix / secrets.nix.
GOOGLE_CLIENT_ID="505807432826-6jpajmrp2od0j1clnmuq59tdbnnov0c8.apps.googleusercontent.com"
MS_CLIENT_ID="0423ac40-9ca9-48e2-9636-56d488ab24ef"
RECIPIENT="age1amd42k828cgyv6kk8pltkknpxklyauz8pnzde73spp8l2w2n5qgsgdsjlu"
MS_FILE="/var/lib/hermes/oauth/ms-hotmail.refresh"

self="$(realpath "$0")"
here="$(dirname "$self")"
repo="$(dirname "$(dirname "$here")")"
py="$here/hermes-oauth-mint.py"

# Provide age + python3 via nix, then re-enter once (guard prevents a loop).
if { ! command -v age >/dev/null 2>&1 || ! command -v python3 >/dev/null 2>&1; } \
   && [ -z "${_HERMES_MINT_BOOTSTRAPPED:-}" ]; then
  export _HERMES_MINT_BOOTSTRAPPED=1
  exec nix shell nixpkgs#age nixpkgs#python3 --command bash "$self" "$@"
fi

usage() {
  echo "usage: $0 google <casual|proper|work>   (any machine w/ repo + master key)" >&2
  echo "       sudo $0 microsoft                 (must run ON antec-pc)" >&2
  exit 1
}

case "${1:-}" in
  google)
    label="${2:-}"
    case "$label" in casual|proper|work) ;; *) usage ;; esac
    secret_age="$repo/secrets/google-oauth-client-secret.age"
    [ -f "$secret_age" ] || { echo "missing $secret_age — store the client secret first" >&2; exit 1; }
    csec="$(age -d -i "$HOME/.config/age/master.key" "$secret_age")"
    # Capture the token first so a failed/cancelled login never overwrites a
    # good secret (set -e aborts before the age write).
    token="$(python3 "$py" google "$GOOGLE_CLIENT_ID" "$csec" --raw)"
    printf '%s' "$token" | age -r "$RECIPIENT" -o "$repo/secrets/google-refresh-$label.age"
    git -C "$repo" add "secrets/google-refresh-$label.age" 2>/dev/null || true
    echo "Stored & staged secrets/google-refresh-$label.age — run nixos-rebuild to deploy."
    ;;
  microsoft)
    host="$(cat /proc/sys/kernel/hostname 2>/dev/null || true)"
    [ "$host" = "antec-pc" ] || { echo "run the microsoft mint ON antec-pc — it writes $MS_FILE on that host (you are on '$host')" >&2; exit 1; }
    [ "$(id -u)" -eq 0 ] || { echo "run with sudo (needs to write $MS_FILE)" >&2; exit 1; }
    token="$(python3 "$py" microsoft "$MS_CLIENT_ID" --raw)"
    install -d -o hermes -g hermes -m 700 "$(dirname "$MS_FILE")"
    umask 077
    printf '%s' "$token" > "$MS_FILE.tmp"
    chown hermes:hermes "$MS_FILE.tmp"
    chmod 600 "$MS_FILE.tmp"
    mv -f "$MS_FILE.tmp" "$MS_FILE"
    echo "Stored $MS_FILE — broker will pick it up on its next run."
    ;;
  *) usage ;;
esac
