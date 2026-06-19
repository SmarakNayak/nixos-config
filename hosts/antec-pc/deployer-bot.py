#!/usr/bin/env python3
"""Telegram-driven nixos-rebuild for antec-pc.

This is the *trusted* half of the Hermes deploy loop. Hermes can only open
pull requests; it can never merge main (code-owner ruleset) and has no access
to this bot's token. This service reads the proposed commit *directly from
GitHub* by SHA and rebuilds that exact revision, so what you approve here is
what runs - independent of anything Hermes claims.

Pure stdlib, no third-party Telegram library, so it needs nothing in the Nix
closure beyond python3 itself (referenced by absolute store path in the unit).
"""

import html
import json
import os
import re
import socket
import subprocess
import threading
import time
import urllib.error
import urllib.parse
import urllib.request

TOKEN = open(os.environ["DEPLOYER_BOT_TOKEN_FILE"]).read().strip()
# Id of your private chat with THIS deployer bot - the sole chat allowed to
# drive deploys. (A private chat's id equals your Telegram user id, so it is the
# same number as your Hermes chat, but it is the deployer bot's chat we honor.)
CHAT_ID = open(os.environ["DEPLOYER_CHAT_ID_FILE"]).read().strip()
REPO = os.environ.get("DEPLOYER_REPO", "SmarakNayak/nixos-config")
ATTR = os.environ.get("DEPLOYER_ATTR", "antec-pc")
BRANCH = os.environ.get("DEPLOYER_BRANCH", "main")

API = "https://api.telegram.org/bot{}/{}"
TELEGRAM_API_HOST = "api.telegram.org"
HTTP_TIMEOUT = 10
POLL_TIMEOUT = 60
# A git object name: 7-40 lowercase hex chars. Anything else never reaches a
# shell or flake ref, so a Telegram message cannot inject arguments.
SHA_RE = re.compile(r"^[0-9a-f]{7,40}$")

_deploying = False
_deploy_lock = threading.Lock()
_getaddrinfo = socket.getaddrinfo


def log(message):
    print(time.strftime("%Y-%m-%dT%H:%M:%S%z"), message, flush=True)


def telegram_ipv4_getaddrinfo(host, port, family=0, type=0, proto=0, flags=0):
    if host == TELEGRAM_API_HOST:
        family = socket.AF_INET
    return _getaddrinfo(host, port, family, type, proto, flags)


socket.getaddrinfo = telegram_ipv4_getaddrinfo


def api(method, http_timeout=HTTP_TIMEOUT, log_empty_updates=False, **params):
    url = API.format(TOKEN, method)
    data = urllib.parse.urlencode(
        {k: v for k, v in params.items() if v is not None}
    ).encode()
    start = time.monotonic()
    try:
        with urllib.request.urlopen(url, data=data, timeout=http_timeout) as r:
            resp = json.load(r)
            elapsed = time.monotonic() - start
            if method != "getUpdates" or resp.get("result") or log_empty_updates:
                log(f"telegram {method} ok in {elapsed:.3f}s")
            return resp
    except urllib.error.HTTPError as e:
        elapsed = time.monotonic() - start
        try:
            resp = json.load(e)
        except Exception:
            resp = {"ok": False, "error": str(e)}
        log(f"telegram {method} http-error in {elapsed:.3f}s: {resp}")
        return resp
    except Exception as e:  # noqa: BLE001 - keep the long-poll loop alive
        elapsed = time.monotonic() - start
        log(f"telegram {method} error in {elapsed:.3f}s: {e}")
        return {"ok": False, "error": str(e)}


def send(text, **kw):
    return api("sendMessage", chat_id=CHAT_ID, text=text,
               parse_mode="HTML", disable_web_page_preview="true", **kw)


def authorized(update_part):
    """Only the single allowlisted private chat may drive deploys."""
    return str(update_part.get("chat", {}).get("id")) == CHAT_ID


def resolve_head(ref):
    """Resolve a branch name to its current SHA straight from GitHub."""
    try:
        out = subprocess.run(
            ["git", "ls-remote", f"https://github.com/{REPO}.git", ref],
            capture_output=True, text=True, timeout=30)
    except Exception:
        return None
    if out.returncode != 0 or not out.stdout.strip():
        return None
    return out.stdout.split()[0]


def commit_subject(sha):
    """First line of the commit message, for display only."""
    url = f"https://api.github.com/repos/{REPO}/commits/{sha}"
    req = urllib.request.Request(
        url, headers={"Accept": "application/vnd.github+json",
                      "User-Agent": "antec-deployer"})
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            data = json.load(r)
        return data["commit"]["message"].splitlines()[0]
    except Exception:
        return "(commit subject unavailable)"


def offer_deploy(ref):
    sha = ref if SHA_RE.match(ref) else resolve_head(ref)
    if not sha:
        send(f"Couldn't resolve <code>{html.escape(ref)}</code> on GitHub.")
        return
    subject = commit_subject(sha)
    keyboard = {"inline_keyboard": [[
        {"text": f"🚀 Deploy {sha[:7]}", "callback_data": f"deploy:{sha}"},
        {"text": "✖ Cancel", "callback_data": "cancel"},
    ]]}
    url = f"https://github.com/{REPO}/commit/{sha}"
    send(
        f"Deploy <b>{ATTR}</b> → <code>{sha[:7]}</code>\n"
        f"{html.escape(subject)}\n\n"
        f'<a href="{url}">Review the diff on GitHub</a>, then confirm.',
        reply_markup=json.dumps(keyboard),
    )


def do_deploy(sha):
    global _deploying
    if not SHA_RE.match(sha):
        send("Refusing to deploy: SHA failed validation.")
        return
    with _deploy_lock:
        if _deploying:
            send("⏳ A deploy is already running. Ignoring.")
            return
        _deploying = True
    try:
        flake = f"github:{REPO}/{sha}#{ATTR}"
        send(f"🚀 Building <code>{sha[:7]}</code>…\n<code>{flake}</code>")
        proc = subprocess.run(
            ["nixos-rebuild", "switch", "--flake", flake, "--refresh"],
            capture_output=True, text=True)
        if proc.returncode == 0:
            send(f"✅ <b>{ATTR}</b> now running <code>{sha[:7]}</code>.")
        else:
            tail = html.escape((proc.stderr or proc.stdout)[-3000:])
            send(
                f"❌ Deploy of <code>{sha[:7]}</code> failed "
                f"(exit {proc.returncode}). The running system is unchanged "
                f"unless activation already started.\n<pre>{tail}</pre>")
    finally:
        with _deploy_lock:
            _deploying = False


def show_status():
    rev = "unknown"
    try:
        rev = subprocess.run(
            ["nixos-version", "--configuration-revision"],
            capture_output=True, text=True, timeout=15).stdout.strip() or rev
    except Exception:
        pass
    head = resolve_head(BRANCH)
    head_line = f"<code>{head[:7]}</code>" if head else "(unreachable)"
    behind = ""
    if head and not rev.startswith(head[:7]) and SHA_RE.match(rev[:40] or ""):
        behind = "  ⚠️ not the latest main"
    send(
        f"<b>{ATTR}</b> status\n"
        f"running revision: <code>{html.escape(rev)}</code>\n"
        f"{BRANCH} on GitHub: {head_line}{behind}")


HELP = (
    "<b>antec deployer</b>\n"
    "/deploy — deploy current main (or <code>/deploy &lt;sha&gt;</code>)\n"
    "/status — show the live revision vs main\n"
    "/rollback — switch to the previous generation\n\n"
    "Hermes opens PRs; only your merge (code-owner) lands on main. "
    "This bot rebuilds the exact GitHub SHA you confirm."
)


def handle_message(msg):
    chat_id = msg.get("chat", {}).get("id")
    text = (msg.get("text") or "").strip()
    cmd = text.split()[0] if text else ""
    msg_date = msg.get("date")
    age = f" age={time.time() - msg_date:.1f}s" if msg_date else ""
    log(f"message chat={chat_id} cmd={cmd or '(none)'}{age}")
    if not authorized(msg):
        log(f"unauthorized message ignored chat={chat_id}")
        return
    if cmd.startswith("/deploy"):
        parts = text.split()
        start_worker(offer_deploy, parts[1] if len(parts) > 1 else BRANCH)
    elif cmd.startswith("/status"):
        start_worker(show_status)
    elif cmd.startswith("/rollback"):
        keyboard = {"inline_keyboard": [[
            {"text": "↩ Roll back", "callback_data": "rollback"},
            {"text": "✖ Cancel", "callback_data": "cancel"},
        ]]}
        send("Roll back to the previous generation?",
             reply_markup=json.dumps(keyboard))
    elif cmd in ("/start", "/help"):
        send(HELP)


def do_rollback():
    global _deploying
    with _deploy_lock:
        if _deploying:
            send("⏳ A deploy is running. Ignoring rollback.")
            return
        _deploying = True
    try:
        send("↩ Rolling back to the previous generation…")
        proc = subprocess.run(
            ["nixos-rebuild", "switch", "--rollback"],
            capture_output=True, text=True)
        if proc.returncode == 0:
            send("✅ Rolled back.")
        else:
            tail = html.escape((proc.stderr or proc.stdout)[-2000:])
            send(f"❌ Rollback failed (exit {proc.returncode}).\n<pre>{tail}</pre>")
    finally:
        with _deploy_lock:
            _deploying = False


def start_worker(target, *args):
    threading.Thread(target=target, args=args, daemon=True).start()


def clear_keyboard(cb):
    """Drop the inline buttons from the message so a choice can't be re-tapped."""
    msg = cb.get("message", {})
    chat = msg.get("chat", {}).get("id")
    mid = msg.get("message_id")
    if chat is not None and mid is not None:
        api("editMessageReplyMarkup", chat_id=chat, message_id=mid,
            reply_markup=json.dumps({"inline_keyboard": []}))


def handle_callback(cb):
    log(f"callback data={cb.get('data', '')}")
    api("answerCallbackQuery", callback_query_id=cb["id"])
    if not authorized(cb.get("message", {})):
        log("unauthorized callback ignored")
        return
    # Remove the keyboard immediately so the same offer can't be actioned twice
    # (e.g. tapping Deploy after Cancel).
    clear_keyboard(cb)
    data = cb.get("data", "")
    if data.startswith("deploy:"):
        start_worker(do_deploy, data.split(":", 1)[1])
    elif data == "rollback":
        start_worker(do_rollback)
    elif data == "cancel":
        send("Cancelled.")


def startup_offset():
    """Skip commands queued while the bot was offline or restarting."""
    resp = api("getUpdates", http_timeout=HTTP_TIMEOUT, timeout=0)
    if not resp.get("ok") or not resp.get("result"):
        log("startup found no queued updates")
        return None
    offset = resp["result"][-1]["update_id"] + 1
    log(f"startup skipped {len(resp['result'])} queued updates; offset={offset}")
    return offset


def main():
    offset = startup_offset()
    send("🤖 Deployer online. /help for commands.")
    log(f"polling started offset={offset}")
    while True:
        resp = api(
            "getUpdates",
            http_timeout=POLL_TIMEOUT + 5,
            log_empty_updates=True,
            offset=offset,
            timeout=POLL_TIMEOUT,
        )
        if not resp.get("ok"):
            time.sleep(5)
            continue
        if resp["result"]:
            log(f"received {len(resp['result'])} update(s)")
        for upd in resp["result"]:
            offset = upd["update_id"] + 1
            try:
                if "message" in upd:
                    handle_message(upd["message"])
                elif "callback_query" in upd:
                    handle_callback(upd["callback_query"])
            except Exception as e:  # noqa: BLE001 - never die on one bad update
                send(f"⚠️ Internal error: <code>{html.escape(str(e))}</code>")


if __name__ == "__main__":
    main()
