#!/usr/bin/env python3
"""One-time OAuth refresh-token minter for Hermes mail/calendar.

Throwaway helper — opens a browser for Google, prints a device-code URL for
Microsoft. It PRINTS the refresh token and then tells you exactly where to
store it (Google -> agenix; Microsoft -> a host file). Storing is manual.

Usage (python3 is not global on NixOS — run it through nix):
  nix run nixpkgs#python3 -- hosts/antec-pc/hermes-oauth-mint.py google <CLIENT_ID> <CLIENT_SECRET>
  nix run nixpkgs#python3 -- hosts/antec-pc/hermes-oauth-mint.py microsoft <CLIENT_ID>
"""
import os, sys, json, time, urllib.parse, urllib.request, urllib.error
import http.server, webbrowser

MS_REFRESH_FILE = "/var/lib/hermes/oauth/ms-hotmail.refresh"

GOOGLE_SCOPE = (
    "https://www.googleapis.com/auth/gmail.readonly "
    "https://www.googleapis.com/auth/calendar.events"
)
MS_SCOPE = "https://graph.microsoft.com/Mail.Read offline_access"


class OAuthError(Exception):
    """An HTTP error from a token endpoint, with the parsed JSON body."""
    def __init__(self, code, body):
        self.code = code
        self.body = body  # dict if JSON-parseable, else {"raw": "..."}
        super().__init__("HTTP %s: %s" % (code, body))


def post(url, data):
    req = urllib.request.Request(url, urllib.parse.urlencode(data).encode())
    try:
        return json.load(urllib.request.urlopen(req))
    except urllib.error.HTTPError as e:
        raw = e.read().decode(errors="replace")
        try:
            body = json.loads(raw)
        except ValueError:
            body = {"raw": raw}
        raise OAuthError(e.code, body)


def google(cid, csec):
    code = {}

    class H(http.server.BaseHTTPRequestHandler):
        def do_GET(s):
            q = urllib.parse.urlparse(s.path).query
            code["c"] = urllib.parse.parse_qs(q).get("code", [None])[0]
            s.send_response(200)
            s.end_headers()
            s.wfile.write(b"Done. Close this tab and return to the terminal.")

        def log_message(s, *a):
            pass

    srv = http.server.HTTPServer(("127.0.0.1", 8765), H)
    redirect = "http://127.0.0.1:8765"
    auth = "https://accounts.google.com/o/oauth2/v2/auth?" + urllib.parse.urlencode({
        "client_id": cid, "redirect_uri": redirect, "response_type": "code",
        "scope": GOOGLE_SCOPE, "access_type": "offline", "prompt": "consent",
    })
    print("Opening browser — sign in as the account you want THIS token for.",
          file=sys.stderr)
    print("If it doesn't open, visit:\n  " + auth + "\n", file=sys.stderr)
    webbrowser.open(auth)
    while "c" not in code:
        srv.handle_request()
    tok = post("https://oauth2.googleapis.com/token", {
        "client_id": cid, "client_secret": csec, "code": code["c"],
        "grant_type": "authorization_code", "redirect_uri": redirect,
    })
    return tok["refresh_token"]


def microsoft(cid):
    dc = post("https://login.microsoftonline.com/consumers/oauth2/v2.0/devicecode",
              {"client_id": cid, "scope": MS_SCOPE})
    print(dc["message"] + "\n", file=sys.stderr)
    interval = dc.get("interval", 5)
    while True:
        time.sleep(interval)
        try:
            tok = post(
                "https://login.microsoftonline.com/consumers/oauth2/v2.0/token", {
                    "client_id": cid,
                    "grant_type": "urn:ietf:params:oauth:grant-type:device_code",
                    "device_code": dc["device_code"],
                })
            return tok["refresh_token"]
        except OAuthError as e:
            err = e.body.get("error") if isinstance(e.body, dict) else None
            if err == "authorization_pending":
                continue  # user hasn't entered the code yet — keep polling
            if err == "slow_down":
                interval += 5
                continue
            raise


GOOGLE_HINT = """
COPY THE TOKEN ABOVE, then store it with agenix (pick the file matching the
account you just signed in as). agenix opens an editor — paste the token, save,
quit:

  cd ~/nixos-config/secrets
  EDITOR=nano nix run github:ryantm/agenix -- -i ~/.config/age/master.key \\
    -e google-refresh-casual.age      # casual | proper | work
"""

MS_HINT = """
COPY THE TOKEN ABOVE, then write it to the host file the broker reads:

  sudo mkdir -p /var/lib/hermes/oauth
  read T    # paste the token, press Enter
  printf '%s' "$T" | sudo tee {path} >/dev/null
  sudo chown -R hermes:hermes /var/lib/hermes/oauth
  sudo chmod 700 /var/lib/hermes/oauth
  sudo chmod 600 {path}
"""


def main():
    args = list(sys.argv[1:])
    raw = False
    if "--raw" in args:
        raw = True            # print ONLY the token on stdout (for scripting)
        args.remove("--raw")
    if not args:
        print(__doc__, file=sys.stderr)
        sys.exit(1)
    # Preserve the real stdout for the token, then point fd 1 at stderr. The
    # browser launcher prints chatter like "Opening in existing browser session."
    # to stdout; redirecting fd 1 (which the browser subprocess inherits) keeps
    # that — and anything else — out of the captured token.
    token_out = os.fdopen(os.dup(1), "w")
    os.dup2(2, 1)
    provider = args[0]
    try:
        if provider == "google":
            rt = google(args[1], args[2])
        elif provider == "microsoft":
            rt = microsoft(args[1])
        else:
            print(__doc__, file=sys.stderr)
            sys.exit(1)
    except OAuthError as e:
        print("\nOAuth error %s:\n%s\n" % (e.code, json.dumps(e.body, indent=2)),
              file=sys.stderr)
        sys.exit(1)
    if raw:
        token_out.write(rt)  # no trailing newline — exact token bytes
        token_out.flush()
        return
    token_out.write("\n==== REFRESH TOKEN ====\n" + rt + "\n=======================\n")
    token_out.flush()
    print(GOOGLE_HINT if provider == "google" else MS_HINT.format(path=MS_REFRESH_FILE))


if __name__ == "__main__":
    main()
